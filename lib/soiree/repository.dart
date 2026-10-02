import 'journal.dart';
import 'soiree_facade.dart';

/// Where soirées are kept between launches of the app.
abstract interface class SoireeRepository {
  /// Starts a new, empty soirée.
  Future<Soiree> create();

  /// The most recently created soirée, if any.
  Future<Soiree?> latest();

  /// Completes once every change made so far is stored; throws if some
  /// could not be.
  Future<void> flush();
}

extension Resumable on SoireeRepository {
  /// The latest soirée when it has a game still in progress.
  Future<Soiree?> resumable() async {
    final soiree = await latest();
    final game = soiree?.state.game;
    return game == null || game.isFinished ? null : soiree;
  }
}

/// Journals kept in memory; outlives the repositories opened on it.
class InMemorySoireeStorage {
  final List<InMemoryJournal> journals = [];
}

class InMemorySoireeRepository implements SoireeRepository {
  InMemorySoireeRepository([InMemorySoireeStorage? storage])
    : _storage = storage ?? InMemorySoireeStorage();

  final InMemorySoireeStorage _storage;

  @override
  Future<Soiree> create() async {
    final journal = InMemoryJournal();
    _storage.journals.add(journal);
    return Soiree(journal);
  }

  @override
  Future<Soiree?> latest() async {
    final journal = _storage.journals.lastOrNull;
    return journal == null ? null : Soiree(journal);
  }

  @override
  Future<void> flush() async {}
}
