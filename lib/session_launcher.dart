import 'dart:async';

import 'package:flutter/foundation.dart';

import 'setup/setup_controller.dart';
import 'session/session.dart';
import 'session/stats.dart' as stats;
import 'session_controller.dart';
import 'share/session_share.dart';
import 'share/share_transport.dart';

/// What keeping a joined session on this device would do: who its
/// [people] would be here, among the players [known] to this device.
typedef KeepProposal = ({
  /// Each person of the session, with the known player of the same name
  /// if there is one.
  List<({Player shared, Player? match})> people,
  List<Player> known,

  /// Whether a session is open here: keeping this one ends it first.
  bool endsOpenSession,
});

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

  /// The copies of joined sessions kept since the app started, by the
  /// code they were joined under: keeping one again replaces its copy.
  final Map<String, String> _keptCopies = {};

  /// What [keep] would do with the session [guest] joined; null when
  /// nothing was played in it.
  Future<KeepProposal?> proposeKeeping(SessionShare guest) async {
    final events = guest.controller.events;
    if (!hasInput(events)) return null;
    final known = await _catalog.active();
    return (
      people: [
        for (final shared in peopleIn(events))
          (
            shared: shared,
            match: known
                .where((p) => p.name.toLowerCase() == shared.name.toLowerCase())
                .firstOrNull,
          ),
      ],
      known: known,
      endsOpenSession: await canResume(),
    );
  }

  /// Keeps a copy of the session [guest] joined in this device's history
  /// and stats, ended. [who] says, by the id each person has in it, which
  /// known player they are; anyone it leaves out becomes a new player.
  /// Two people cannot be the same player. A session open here is ended
  /// first; a copy kept earlier from the same share is replaced.
  Future<void> keep(SessionShare guest, Map<String, Player> who) async {
    final events = guest.controller.events;
    final byId = <String, Player>{};
    for (final person in peopleIn(events)) {
      byId[person.id] = who[person.id] ?? await _addAs(person.name);
    }
    if (byId.values.map((p) => p.id).toSet().length != byId.length) {
      throw ArgumentError.value(who, 'who', 'two people are one player');
    }
    (await _repository.resumable())?.endSession();
    final code = guest.code;
    if (_keptCopies.remove(code) case final earlier?) {
      try {
        await _repository.delete(earlier);
      } on ArgumentError {
        // Deleted from the history meanwhile.
      }
    }
    final copy = await _repository.create();
    final written = copy.rewrite(0, replacePlayers(events, byId));
    if (written is Rejected) throw StateError(written.reason);
    if (!copy.state.isEnded) copy.endSession();
    await _catalog.markPlayed(byId.values);
    await _repository.flush();
    if (code != null) _keptCopies[code] = (await _repository.played()).first.id;
  }

  /// A new player called [name], or as near as the catalog allows when
  /// the name is taken.
  Future<Player> _addAs(String name) async {
    var free = name;
    for (var n = 2; await _catalog.nameProblem(free) != null; n++) {
      free = '$name ($n)';
    }
    return _catalog.add(free);
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
