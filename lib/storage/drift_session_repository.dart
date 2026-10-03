import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../session/event_codec.dart';
import '../session/session.dart';
import 'app_database.dart';

/// Keeps sessions in the app's SQLite database.
class DriftSessionRepository implements SessionRepository {
  DriftSessionRepository(this._db);

  final AppDatabase _db;

  /// Writes run one after the other, in the order commands were accepted.
  Future<void> _writes = Future.value();

  /// The first write that failed. Once set, nothing more is written: a
  /// journal with a hole would replay into a different game.
  Object? _failure;

  @override
  Future<Session> create() async {
    await _writes;
    final id = await _db.into(_db.sessions).insert(SessionsCompanion.insert());
    return Session(_DriftJournal(id, const [], _enqueue, _db));
  }

  @override
  Future<Session?> latest() async {
    await _writes;
    final session =
        await (_db.select(_db.sessions)
              ..orderBy([(s) => OrderingTerm.desc(s.id)])
              ..limit(1))
            .getSingleOrNull();
    if (session == null) return null;
    final events = await _eventsOf(session.id);
    return Session(_DriftJournal(session.id, events, _enqueue, _db));
  }

  @override
  Future<List<SessionRecord>> history() async {
    await _writes;
    final sessions = await (_db.select(
      _db.sessions,
    )..orderBy([(s) => OrderingTerm.desc(s.id)])).get();
    // One query for every journal, grouped here, rather than one per session.
    final eventsBySession = <int, List<SessionEvent>>{};
    final rows =
        await (_db.select(_db.sessionEvents)..orderBy([
              (e) => OrderingTerm.asc(e.sessionId),
              (e) => OrderingTerm.asc(e.seq),
            ]))
            .get();
    for (final row in rows) {
      (eventsBySession[row.sessionId] ??= []).add(_decode(row));
    }
    return [
      for (final session in sessions)
        if (Session(InMemoryJournal.of(eventsBySession[session.id] ?? const []))
                .state
            case final state when isHistory(state))
          SessionRecord(
            id: '${session.id}',
            createdAt: session.createdAt,
            state: state,
          ),
    ];
  }

  @override
  Future<void> delete(String id) async {
    await _writes;
    final sessionId =
        int.tryParse(id) ??
        (throw ArgumentError.value(id, 'id', 'no such session'));
    await _db.transaction(() async {
      await (_db.delete(
        _db.sessionEvents,
      )..where((e) => e.sessionId.equals(sessionId))).go();
      final deleted = await (_db.delete(
        _db.sessions,
      )..where((s) => s.id.equals(sessionId))).go();
      if (deleted == 0) {
        throw ArgumentError.value(id, 'id', 'no such session');
      }
    });
  }

  Future<List<SessionEvent>> _eventsOf(int sessionId) async {
    final rows =
        await (_db.select(_db.sessionEvents)
              ..where((e) => e.sessionId.equals(sessionId))
              ..orderBy([(e) => OrderingTerm.asc(e.seq)]))
            .get();
    return [for (final row in rows) _decode(row)];
  }

  SessionEvent _decode(StoredEvent row) =>
      decodeEvent(row.type, jsonDecode(row.payload) as Map<String, Object?>);

  /// Completes once every write has run; throws if one of them failed.
  @override
  Future<void> flush() async {
    await _writes;
    if (_failure case final failure?) throw failure;
  }

  void _enqueue(Future<void> Function() write) {
    _writes = _writes.then((_) async {
      if (_failure != null) return;
      try {
        await write();
      } catch (error) {
        // The game goes on from memory; what is stored stays a consistent
        // prefix of it.
        _failure = error;
        debugPrint('Stopped storing session events: $error');
      }
    });
  }
}

/// A session's journal: read from memory, written through to the database.
class _DriftJournal implements SessionJournal {
  _DriftJournal(
    this._sessionId,
    List<SessionEvent> events,
    this._enqueue,
    this._db,
  ) : _events = [...events];

  final int _sessionId;
  final List<SessionEvent> _events;
  final void Function(Future<void> Function()) _enqueue;
  final AppDatabase _db;

  @override
  List<SessionEvent> get events => List.unmodifiable(_events);

  @override
  void append(SessionEvent event) {
    final seq = _events.length;
    _events.add(event);
    final encoded = encodeEvent(event);
    _enqueue(
      () => _db
          .into(_db.sessionEvents)
          .insert(
            SessionEventsCompanion.insert(
              sessionId: _sessionId,
              seq: seq,
              type: encoded.type,
              payload: jsonEncode(encoded.payload),
            ),
          ),
    );
  }

  @override
  void removeLast() {
    _events.removeLast();
    final seq = _events.length;
    _enqueue(
      () => (_db.delete(
        _db.sessionEvents,
      )..where((e) => e.sessionId.equals(_sessionId) & e.seq.equals(seq))).go(),
    );
  }
}
