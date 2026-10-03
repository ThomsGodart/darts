import 'setup/setup_controller.dart';
import 'soiree/soiree.dart';
import 'soiree_controller.dart';

/// Opens soirées for the home screen, so widgets never touch storage.
class SoireeLauncher {
  SoireeLauncher(this._repository, this._catalog);

  final SoireeRepository _repository;
  final PlayerCatalog _catalog;

  /// Whether a soirée was left with a game in progress.
  Future<bool> canResume() async => await _repository.resumable() != null;

  /// The soirée whose game was left in progress, if any.
  Future<SoireeController?> resume() async {
    final soiree = await _repository.resumable();
    return soiree == null ? null : SoireeController(soiree);
  }

  /// State for the setup screen: blank for a new soirée, or starting from
  /// [from] for the next game of one.
  SetupController newSetup({GameSetup? from}) =>
      SetupController(_catalog, from: from);

  /// A new soirée with its first game started as [setup] says.
  Future<SoireeController> newGame(GameSetup setup) async {
    final controller = SoireeController(await _repository.create());
    final started = controller.startGame(setup.players, config: setup.config);
    if (started is Rejected) {
      controller.dispose();
      throw StateError('The setup was refused: ${started.reason}');
    }
    // Only now do these players have a game to their name.
    await _catalog.markPlayed(setup.players);
    return controller;
  }

  /// Starts the next game of [soiree] as [setup] says: players may have
  /// joined, left or changed order, or the rules changed.
  Future<void> nextGame(SoireeController soiree, GameSetup setup) async {
    final started = soiree.startGame(setup.players, config: setup.config);
    if (started is Rejected) {
      throw StateError('The setup was refused: ${started.reason}');
    }
    await _catalog.markPlayed(setup.players);
  }

  /// Stores everything played so far, e.g. before the app is backgrounded.
  Future<void> flush() => _repository.flush();
}
