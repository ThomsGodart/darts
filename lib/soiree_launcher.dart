import 'soiree/soiree.dart';
import 'soiree_controller.dart';

/// Opens soirées for the home screen, so widgets never touch storage.
class SoireeLauncher {
  SoireeLauncher(this._repository);

  final SoireeRepository _repository;

  /// The soirée whose game was left in progress, if any.
  Future<SoireeController?> resumable() async {
    final soiree = await _repository.resumable();
    return soiree == null ? null : SoireeController(soiree);
  }

  /// A new soirée with its first game already started.
  Future<SoireeController> newGame(
    List<Player> players, {
    X01Config config = const X01Config(),
  }) async {
    final controller = SoireeController(await _repository.create());
    controller.startGame(players, config: config);
    return controller;
  }
}
