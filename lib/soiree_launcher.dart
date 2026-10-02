import 'soiree/soiree.dart';
import 'soiree_controller.dart';

/// Opens soirées for the home screen, so widgets never touch storage.
class SoireeLauncher {
  SoireeLauncher(this._repository);

  final SoireeRepository _repository;

  /// Whether a soirée was left with a game in progress.
  Future<bool> canResume() async => await _repository.resumable() != null;

  /// The soirée whose game was left in progress, if any.
  Future<SoireeController?> resume() async {
    final soiree = await _repository.resumable();
    return soiree == null ? null : SoireeController(soiree);
  }

  /// A new soirée with its first game already started.
  Future<SoireeController> newGame(List<Player> players) async {
    final controller = SoireeController(await _repository.create());
    controller.startGame(players);
    return controller;
  }

  /// Stores everything played so far, e.g. before the app is backgrounded.
  Future<void> flush() => _repository.flush();
}
