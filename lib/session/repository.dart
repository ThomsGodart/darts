import 'events.dart';
import 'journal.dart';
import 'session_facade.dart';
import 'state.dart';

/// A stored session, as the history shows it.
class SessionRecord {
  const SessionRecord({
    required this.id,
    required this.createdAt,
    required this.state,
    this.gameStartedAt = const [],
  });

  final String id;
  final DateTime createdAt;
  final SessionState state;

  /// When each game of [state] was started, in order.
  final List<DateTime> gameStartedAt;
}

/// Where sessions are kept between launches of the app.
abstract interface class SessionRepository {
  /// Starts a new, empty session.
  Future<Session> create();

  /// The most recently created session, if any.
  Future<Session?> latest();

  /// Every session that had at least one game, newest first: the ended
  /// ones and the one still open.
  Future<List<SessionRecord>> played();

  /// Deletes a session and its journal for good; throws [ArgumentError] for
  /// an id this repository never gave.
  Future<void> delete(String id);

  /// Completes once every change made so far is stored; throws if some
  /// could not be.
  Future<void> flush();

  /// First storage error that stopped further writes, if any.
  Object? get persistFailure;

  /// Registers [onFailure], called once when [persistFailure] becomes set.
  void watchPersistFailure(void Function() onFailure);
}

extension History on SessionRepository {
  /// Ended sessions that had at least one game, newest first. The open
  /// session is not history yet: it is resumed instead.
  Future<List<SessionRecord>> history() async => [
    for (final record in await played())
      if (record.state.isEnded) record,
  ];

  /// Deletes every session of the [history] for good; the open session
  /// stays.
  Future<void> deleteHistory() async {
    for (final record in await history()) {
      await delete(record.id);
    }
  }
}

extension Resumable on SessionRepository {
  /// The latest session when it was not ended: its game may be in progress,
  /// or over and waiting for Rejouer.
  Future<Session?> resumable() async {
    final session = await latest();
    if (session == null) return null;
    final state = session.state;
    return state.game == null || state.isEnded ? null : session;
  }
}

class _StoredSession {
  _StoredSession(this.id, this.journal, this.createdAt);

  final String id;
  final DateTime createdAt;
  final InMemoryJournal journal;
}

/// Journals kept in memory; outlives the repositories opened on it.
class InMemorySessionStorage {
  /// What time it is: tests set it to date sessions and games.
  DateTime Function() now = DateTime.now;

  final List<_StoredSession> _sessions = [];
  int _nextId = 1;

  /// Journals, oldest first.
  List<InMemoryJournal> get journals => [for (final s in _sessions) s.journal];
}

class InMemorySessionRepository implements SessionRepository {
  InMemorySessionRepository([InMemorySessionStorage? storage])
    : _storage = storage ?? InMemorySessionStorage();

  final InMemorySessionStorage _storage;
  Object? _failure;
  void Function()? _onFailure;

  @override
  Future<Session> create() async {
    final journal = InMemoryJournal(now: () => _storage.now());
    _storage._sessions.add(
      _StoredSession('${_storage._nextId++}', journal, _storage.now()),
    );
    return Session(journal);
  }

  @override
  Future<Session?> latest() async {
    final journal = _storage.journals.lastOrNull;
    return journal == null ? null : Session(journal);
  }

  @override
  Future<List<SessionRecord>> played() async => [
    for (final stored in _storage._sessions.reversed)
      if (Session(stored.journal).state case final state
          when state.game != null)
        SessionRecord(
          id: stored.id,
          createdAt: stored.createdAt,
          state: state,
          gameStartedAt: [
            for (final (i, event) in stored.journal.events.indexed)
              if (event is GameStarted) stored.journal.recordedAt[i],
          ],
        ),
  ];

  @override
  Future<void> delete(String id) async {
    final before = _storage._sessions.length;
    _storage._sessions.removeWhere((s) => s.id == id);
    if (_storage._sessions.length == before) {
      throw ArgumentError.value(id, 'id', 'no such session');
    }
  }

  @override
  Future<void> flush() async {
    if (_failure case final failure?) throw failure;
  }

  @override
  Object? get persistFailure => _failure;

  @override
  void watchPersistFailure(void Function() onFailure) => _onFailure = onFailure;

  /// Test helper: stop "writes" and notify watchers, like a disk error.
  void simulatePersistFailure([Object error = 'disk full']) {
    if (_failure != null) return;
    _failure = error;
    _onFailure?.call();
  }
}
