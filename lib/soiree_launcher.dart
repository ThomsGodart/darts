import 'setup/setup_controller.dart';
import 'soiree/soiree.dart';
import 'soiree_controller.dart';

/// Opens soirées for the home screen, so widgets never touch storage.
class SoireeLauncher {
  SoireeLauncher(this._repository, this._catalog);

  final SoireeRepository _repository;
  final PlayerCatalog _catalog;

  /// Whether a soirée was left open: mid-game, or between two games.
  Future<bool> canResume() async => await _repository.resumable() != null;

  /// The soirée left open, if any.
  Future<SoireeController?> resume() async {
    final soiree = await _repository.resumable();
    return soiree == null ? null : SoireeController(soiree);
  }

  /// State for the setup screen: blank for a new soirée, or starting from
  /// [from] for the next game of one.
  SetupController newSetup({GameSetup? from}) =>
      SetupController(_catalog, from: from);

  /// A new soirée with its first game started as [setup] says. A soirée
  /// left open is ended first, so it reaches the history.
  Future<SoireeController> newGame(GameSetup setup) async {
    (await _repository.resumable())?.endSoiree();
    final controller = SoireeController(await _repository.create());
    try {
      await _start(controller, setup);
    } catch (_) {
      controller.dispose();
      rethrow;
    }
    return controller;
  }

  /// Starts the next game of [soiree] as [setup] says: players may have
  /// joined, left or changed order, or the rules changed.
  Future<void> nextGame(SoireeController soiree, GameSetup setup) =>
      _start(soiree, setup);

  Future<void> _start(SoireeController soiree, GameSetup setup) async {
    final started = soiree.startGame(setup.players, config: setup.config);
    if (started is Rejected) {
      throw StateError('The setup was refused: ${started.reason}');
    }
    // Only now do these players have a game to their name.
    await _catalog.markPlayed(setup.players);
  }

  /// Stores everything played so far, e.g. before the app is backgrounded.
  Future<void> flush() => _repository.flush();
}
