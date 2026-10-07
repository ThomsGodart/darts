import 'dart:async';

import 'package:flutter/foundation.dart';

import 'setup/setup_controller.dart';
import 'session/session.dart';
import 'session/stats.dart' as stats;
import 'session_controller.dart';
import 'share/session_share.dart';
import 'share/share_transport.dart';

/// Opens sessions for the home screen, so widgets never touch storage.
class SessionLauncher extends ChangeNotifier {
  SessionLauncher(this._repository, this._catalog, {this._shareTransport}) {
    _repository.watchPersistFailure(notifyListeners);
  }

  final SessionRepository _repository;
  final PlayerCatalog _catalog;

  /// What sessions are shared over; without it nothing is shared.
  final ShareTransport? _shareTransport;

  /// How the open session was shared when its game screen was last
  /// left: null when it was not. Opening it again shares it the same
  /// way, so the devices that joined find it where it was.
  ({String code, bool inputLocked})? _lastShare;

  /// Whether sessions can be shared with other devices, and joined.
  bool get canShare => _shareTransport != null;

  /// The share of the open session [session], for as long as its game
  /// screen is up; null when sessions cannot be shared. Back on the line
  /// already if it was shared when it was last left — without network it
  /// stays wanted, and off the line.
  SessionShare? shareOf(SessionController session) {
    final transport = _shareTransport;
    if (transport == null) return null;
    final last = _lastShare;
    final share = SessionShare(
      transport,
      session,
      code: last?.code,
      lockInput: last?.inputLocked ?? false,
    );
    if (last != null) unawaited(share.start().catchError((Object _) {}));
    return share;
  }

  /// Takes back a share made by [shareOf] or [join], the game screen
  /// gone.
  void closeShare(SessionShare share) {
    if (!share.isGuest) {
      final code = share.code;
      _lastShare = share.isWanted && code != null
          ? (code: code, inputLocked: share.inputLocked)
          : null;
    }
    share.dispose();
  }

  /// Joins the session another device shares under [code]: played here
  /// too, and kept there. Throws what [SessionShare.join] throws.
  Future<SessionShare> join(String code) =>
      SessionShare.join(_shareTransport!, code);

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
    // Its guests are not left watching a game nobody plays any more.
    if ((_lastShare, _shareTransport) case (final last?, final transport?)) {
      _lastShare = null;
      unawaited(SessionShare.announceGone(transport, last.code));
    }
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
    await _catalog.markPlayed(peopleOf(setup.players));
  }

  /// Past and open sessions, newest first.
  Future<List<SessionRecord>> history() => _repository.history();

  /// Every game played, in ended sessions and the open one, oldest first:
  /// what the stats are counted over.
  Future<List<PlayedGame>> playedGames() async =>
      stats.playedGames(await _repository.played());

  /// Deletes a session from the history for good.
  Future<void> deleteSession(SessionRecord record) =>
      _repository.delete(record.id);

  /// Deletes every ended session for good; the open one stays.
  Future<void> deleteHistory() => _repository.deleteHistory();

  /// Stores everything played so far, e.g. before the app is backgrounded.
  Future<void> flush() => _repository.flush();
}
