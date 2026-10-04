import 'commands.dart';
import 'dart.dart';
import 'events.dart';
import 'fold.dart';
import 'journal.dart';
import 'player.dart';
import 'state.dart';
import 'game_config.dart';
import 'x01_rules.dart';

/// Single entry point to the session domain.
///
/// Commands are validated against the current state; accepted ones are
/// appended to the [SessionJournal] and folded into a new [state].
class Session {
  Session(this._journal) : _state = foldEvents(_journal.events);

  final SessionJournal _journal;
  SessionState _state;

  SessionState get state => _state;

  /// Starts a game with [players] in throwing order: the first game of the
  /// session, or the next one with players added, removed or reordered.
  CommandResult startGame(
    List<Player> players, {
    GameConfig config = const X01Config(),
  }) {
    if (_state.isEnded) return const Rejected('The session is over');
    if (players.isEmpty) return const Rejected('A game needs players');
    if (players.length > maxPlayers) {
      return const Rejected('At most $maxPlayers players');
    }
    if (players.length < config.minPlayers) {
      return Rejected('These rules need at least ${config.minPlayers} players');
    }
    if (players.map((p) => p.id).toSet().length != players.length) {
      return const Rejected('A player cannot play twice in a game');
    }
    if (!config.isValid) {
      return const Rejected('These rules cannot be played');
    }
    final game = _state.game;
    if (game != null && !game.isFinished) {
      return const Rejected('A game is already in progress');
    }
    return _record(
      GameStarted(players: List.unmodifiable(players), config: config),
    );
  }

  /// Starts the next game with the same players, whoever started the last
  /// one now throwing last; with the same rules unless [config] is given.
  CommandResult rematch({GameConfig? config}) {
    final game = _state.game;
    if (game == null) return const Rejected('No game to play again');
    if (!game.isFinished) return const Rejected('The game is not over');
    return startGame(game.rematchOrder, config: config ?? game.config);
  }

  /// Ends the session: normally between two games; a game in progress, if
  /// the session is abandoned, stays unfinished.
  CommandResult endSession() {
    if (_state.isEnded) return const Rejected('The session is already over');
    return _record(const SessionEnded());
  }

  /// Submits a visit by its total. When it brings the remaining score to
  /// exactly 0, [dartsAtCheckout] must say how many darts it took (one of
  /// [X01Game.checkoutDartOptions]); otherwise it must be omitted. Only
  /// X01 and Count-Up games take totals. [dartsAtDouble] optionally says
  /// how many darts of an X01 visit were thrown at a finish.
  CommandResult submitVisitTotal(
    int score, {
    int? dartsAtCheckout,
    int? dartsAtDouble,
  }) {
    final current = _state.game;
    if (current == null || current.isFinished || _state.isEnded) {
      return _notInProgress(current);
    }
    if (current is CountUpGame) {
      if (current.dartsInVisit.isNotEmpty) {
        return const Rejected('This visit is being entered dart by dart');
      }
      if (dartsAtCheckout != null) {
        return const Rejected('A dart count is only given on a checkout');
      }
      if (!isPossibleVisitTotal(score)) {
        return Rejected('$score cannot be scored with three darts');
      }
      return _record(VisitTotalSubmitted(score));
    }
    if (current is! X01Game) {
      return const Rejected('This game is entered dart by dart');
    }
    final game = current;
    if (game.dartsInVisit.isNotEmpty) {
      return const Rejected('This visit is being entered dart by dart');
    }
    if (!isPossibleVisitTotal(score)) {
      return Rejected('$score cannot be scored with three darts');
    }
    if (score != game.activeScore.remaining) {
      if (dartsAtCheckout != null) {
        return const Rejected('A dart count is only given on a checkout');
      }
      if (dartsAtDouble != null &&
          (dartsAtDouble < 0 || dartsAtDouble > dartsPerVisit)) {
        return Rejected('$dartsAtDouble darts cannot be thrown at a double');
      }
      return _record(VisitTotalSubmitted(score, dartsAtDouble: dartsAtDouble));
    }
    // From here the visit would bring the remaining score to exactly 0.
    final options = game.checkoutDartOptions(score);
    if (options.isEmpty) return Rejected('$score cannot be checked out');
    if (dartsAtCheckout == null) {
      return const Rejected('A checkout needs its dart count');
    }
    if (!options.contains(dartsAtCheckout)) {
      return Rejected('$score cannot be checked out in $dartsAtCheckout');
    }
    if (dartsAtDouble != null &&
        (dartsAtDouble < 1 || dartsAtDouble > dartsAtCheckout)) {
      return Rejected(
        'A checkout in $dartsAtCheckout cannot take $dartsAtDouble at a double',
      );
    }
    return _record(
      VisitTotalSubmitted(
        score,
        darts: dartsAtCheckout,
        dartsAtDouble: dartsAtDouble,
      ),
    );
  }

  /// Enters the next dart of the active player's visit. The visit ends by
  /// itself on the third dart, a bust or a checkout.
  CommandResult throwDart(Dart dart) {
    final game = _state.game;
    if (game == null || game.isFinished || _state.isEnded) {
      return _notInProgress(game);
    }
    if (game is KillerGame && game.phase != KillerPhase.playing) {
      return const Rejected('Assign numbers before throwing');
    }
    if (!dart.isValid) return Rejected('No such dart: $dart');
    return _record(DartThrown(dart));
  }

  /// Ends the active player's visit before its third dart, the darts left
  /// counting as misses. One [undo] takes it back whole.
  CommandResult endVisit() {
    final game = _state.game;
    if (game == null || game.isFinished || _state.isEnded) {
      return _notInProgress(game);
    }
    if (game is KillerGame && game.phase != KillerPhase.playing) {
      return const Rejected('Assign numbers before throwing');
    }
    return _record(const VisitEnded());
  }

  /// Claims [sector] (1–20) for the active player during Killer attribution.
  CommandResult assignNumber(int sector) {
    final game = _state.game;
    if (game == null || game.isFinished || _state.isEnded) {
      return _notInProgress(game);
    }
    if (game is! KillerGame) {
      return const Rejected('Only Killer assigns numbers');
    }
    if (game.phase != KillerPhase.assigning) {
      return const Rejected('Numbers are already assigned');
    }
    if (sector < 1 || sector > 20) {
      return Rejected('No such sector: $sector');
    }
    if (game.takenNumbers.contains(sector)) {
      return const Rejected('That number is already taken');
    }
    return _record(NumberAssigned(sector));
  }

  /// Whether there is an input of the current game to take back.
  bool get canUndo => switch (_journal.events.lastOrNull) {
    VisitTotalSubmitted() ||
    DartThrown() ||
    VisitEnded() ||
    NumberAssigned() => true,
    GameStarted() || SessionEnded() || null => false,
  };

  /// Takes back the latest input, even after the game was won.
  CommandResult undo() {
    if (!canUndo) return const Rejected('Nothing to undo');
    _journal.removeLast();
    _state = foldEvents(_journal.events);
    return const Accepted();
  }

  /// Why no input can be entered into [game]: missing, finished, or left
  /// unfinished by an abandoned session.
  Rejected _notInProgress(Game? game) => switch (game) {
    null => const Rejected('No game in progress'),
    _ when _state.isEnded => const Rejected('The session is over'),
    _ => const Rejected('The game is over'),
  };

  CommandResult _record(SessionEvent event) {
    _journal.append(event);
    _state = applyEvent(_state, event);
    return const Accepted();
  }
}
