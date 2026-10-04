import 'package:flutter/foundation.dart';

import 'setup/setup_controller.dart';
import 'session/player_stats.dart' as session_stats;
import 'session/session.dart';
import 'session_controller.dart';

/// Opens sessions for the home screen, so widgets never touch storage.
class SessionLauncher extends ChangeNotifier {
  SessionLauncher(this._repository, this._catalog) {
    _repository.watchPersistFailure(notifyListeners);
  }

  final SessionRepository _repository;
  final PlayerCatalog _catalog;

  /// Set when disk writes have stopped; resume may miss later visits.
  Object? get persistFailure => _repository.persistFailure;

  /// Whether a session was left open: mid-game, or between two games.
  Future<bool> canResume() async => await _repository.resumable() != null;

  /// The session left open, if any.
  Future<SessionController?> resume() async {
    final session = await _repository.resumable();
    return session == null ? null : SessionController(session);
  }

  /// Who played the latest game, in its throwing order, and its rules:
  /// what a new session is offered to start from. Null before any game.
  Future<GameSetup?> lastSetup() async {
    final game = (await _repository.latest())?.state.game;
    return game == null ? null : (players: game.players, config: game.config);
  }

  /// State for the setup screen: blank for a new session, or starting from
  /// [from] for the next game of one.
  SetupController newSetup({GameSetup? from}) =>
      SetupController(_catalog, from: from);

  /// A new session with its first game started as [setup] says. A session
  /// left open is ended first, so it reaches the history; a setup the
  /// rules refuse throws before anything is touched.
  Future<SessionController> newGame(GameSetup setup) async {
    final dryRun = Session(InMemoryJournal())
        .startGame(setup.players, config: setup.config);
    if (dryRun is Rejected) {
      throw StateError('The setup was refused: ${dryRun.reason}');
    }
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

  /// Everyone's stats over every session, the open one included.
  Future<List<PlayerStats>> playerStats() async {
    final open = await _repository.resumable();
    final ended = await _repository.history();
    return session_stats.playerStats([
      // Oldest first, so the latest name of a renamed player wins.
      for (final record in ended.reversed) record.state,
      if (open != null) open.state,
    ]);
  }

  /// Deletes a session from the history for good.
  Future<void> deleteSession(SessionRecord record) =>
      _repository.delete(record.id);

  /// Stores everything played so far, e.g. before the app is backgrounded.
  Future<void> flush() => _repository.flush();
}
