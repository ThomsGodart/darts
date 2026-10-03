import 'journal.dart';
import 'soiree_facade.dart';
import 'state.dart';

/// A stored soirée, as the history shows it.
class SoireeRecord {
  const SoireeRecord({
    required this.id,
    required this.createdAt,
    required this.state,
  });

  final String id;
  final DateTime createdAt;
  final SoireeState state;
}

/// Where soirées are kept between launches of the app.
abstract interface class SoireeRepository {
  /// Starts a new, empty soirée.
  Future<Soiree> create();

  /// The most recently created soirée, if any.
  Future<Soiree?> latest();

  /// Every soirée that had at least one game, newest first.
  Future<List<SoireeRecord>> history();

  /// Deletes a soirée and its journal for good.
  Future<void> delete(String id);

  /// Completes once every change made so far is stored; throws if some
  /// could not be.
  Future<void> flush();
}

extension Resumable on SoireeRepository {
  /// The latest soirée when it was not ended: its game may be in progress,
  /// or over and waiting for Rejouer.
  Future<Soiree?> resumable() async {
    final soiree = await latest();
    if (soiree == null) return null;
    final state = soiree.state;
    return state.game == null || state.isEnded ? null : soiree;
  }
}

/// Journals kept in memory; outlives the repositories opened on it.
class InMemorySoireeStorage {
  final List<({String id, DateTime createdAt, InMemoryJournal journal})>
  entries = [];
  int nextId = 1;

  /// Journals, oldest first.
  List<InMemoryJournal> get journals => [for (final e in entries) e.journal];
}

class InMemorySoireeRepository implements SoireeRepository {
  InMemorySoireeRepository([InMemorySoireeStorage? storage])
    : _storage = storage ?? InMemorySoireeStorage();

  final InMemorySoireeStorage _storage;

  @override
  Future<Soiree> create() async {
    final journal = InMemoryJournal();
    _storage.entries.add((
      id: '${_storage.nextId++}',
      createdAt: DateTime.now(),
      journal: journal,
    ));
    return Soiree(journal);
  }

  @override
  Future<Soiree?> latest() async {
    final journal = _storage.journals.lastOrNull;
    return journal == null ? null : Soiree(journal);
  }

  @override
  Future<List<SoireeRecord>> history() async => [
    for (final entry in _storage.entries.reversed)
      if (Soiree(entry.journal).state case final state when state.game != null)
        SoireeRecord(id: entry.id, createdAt: entry.createdAt, state: state),
  ];

  @override
  Future<void> delete(String id) async =>
      _storage.entries.removeWhere((e) => e.id == id);

  @override
  Future<void> flush() async {}
}
