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

  /// Ended soirées that had at least one game, newest first. The open
  /// soirée is not history yet: it is resumed instead.
  Future<List<SoireeRecord>> history();

  /// Deletes a soirée and its journal for good; throws [ArgumentError] for
  /// an id this repository never gave.
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

/// Whether a soirée belongs in the history.
bool isHistory(SoireeState state) => state.isEnded && state.game != null;

class _StoredSoiree {
  _StoredSoiree(this.id, this.journal) : createdAt = DateTime.now();

  final String id;
  final DateTime createdAt;
  final InMemoryJournal journal;
}

/// Journals kept in memory; outlives the repositories opened on it.
class InMemorySoireeStorage {
  final List<_StoredSoiree> _soirees = [];
  int _nextId = 1;

  /// Journals, oldest first.
  List<InMemoryJournal> get journals => [for (final s in _soirees) s.journal];
}

class InMemorySoireeRepository implements SoireeRepository {
  InMemorySoireeRepository([InMemorySoireeStorage? storage])
    : _storage = storage ?? InMemorySoireeStorage();

  final InMemorySoireeStorage _storage;

  @override
  Future<Soiree> create() async {
    final journal = InMemoryJournal();
    _storage._soirees.add(_StoredSoiree('${_storage._nextId++}', journal));
    return Soiree(journal);
  }

  @override
  Future<Soiree?> latest() async {
    final journal = _storage.journals.lastOrNull;
    return journal == null ? null : Soiree(journal);
  }

  @override
  Future<List<SoireeRecord>> history() async => [
    for (final stored in _storage._soirees.reversed)
      if (Soiree(stored.journal).state case final state when isHistory(state))
        SoireeRecord(id: stored.id, createdAt: stored.createdAt, state: state),
  ];

  @override
  Future<void> delete(String id) async {
    final before = _storage._soirees.length;
    _storage._soirees.removeWhere((s) => s.id == id);
    if (_storage._soirees.length == before) {
      throw ArgumentError.value(id, 'id', 'no such soirée');
    }
  }

  @override
  Future<void> flush() async {}
}
