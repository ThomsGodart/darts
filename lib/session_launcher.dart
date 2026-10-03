import 'setup/setup_controller.dart';
import 'session/session.dart';
import 'session_controller.dart';

/// Opens sessions for the home screen, so widgets never touch storage.
class SessionLauncher {
  SessionLauncher(this._repository, this._catalog);

  final SessionRepository _repository;
  final PlayerCatalog _catalog;

  /// Whether a session was left open: mid-game, or between two games.
  Future<bool> canResume() async => await _repository.resumable() != null;

  /// The session left open, if any.
  Future<SessionController?> resume() async {
    final session = await _repository.resumable();
    return session == null ? null : SessionController(session);
  }

  /// State for the setup screen: blank for a new session, or starting from
  /// [from] for the next game of one.
  SetupController newSetup({GameSetup? from}) =>
      SetupController(_catalog, from: from);

  /// A new session with its first game started as [setup] says. A session
  /// left open is ended first, so it reaches the history.
  Future<SessionController> newGame(GameSetup setup) async {
    (await _repository.resumable())?.endSession();
    final controller = SessionController(await _repository.create());
    try {
      await _start(controller, setup);
    } catch (_) {
      controller.dispose();
      rethrow;
    }
    return controller;
  }

  /// Starts the next game of [session] as [setup] says: players may have
  /// joined, left or changed order, or the rules changed.
  Future<void> nextGame(SessionController session, GameSetup setup) =>
      _start(session, setup);

  Future<void> _start(SessionController session, GameSetup setup) async {
    final started = session.startGame(setup.players, config: setup.config);
    if (started is Rejected) {
      throw StateError('The setup was refused: ${started.reason}');
    }
    // Only now do these players have a game to their name.
    await _catalog.markPlayed(setup.players);
  }

  /// Past and open sessions, newest first.
  Future<List<SessionRecord>> history() => _repository.history();

  /// Deletes a session from the history for good.
  Future<void> deleteSession(SessionRecord record) =>
      _repository.delete(record.id);

  /// Stores everything played so far, e.g. before the app is backgrounded.
  Future<void> flush() => _repository.flush();
}
