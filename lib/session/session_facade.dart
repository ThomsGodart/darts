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
  /// X01 games take totals.
  CommandResult submitVisitTotal(int score, {int? dartsAtCheckout}) {
    final current = _state.game;
    if (current == null || current.isFinished || _state.isEnded) {
      return _notInProgress(current);
    }
    if (current is! X01Game) {
      return const Rejected('Only X01 visits are entered as a total');
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
      return _record(VisitTotalSubmitted(score));
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
    return _record(VisitTotalSubmitted(score, darts: dartsAtCheckout));
  }

  /// Enters the next dart of the active player's visit. The visit ends by
  /// itself on the third dart, a bust or a checkout.
  CommandResult throwDart(Dart dart) {
    final game = _state.game;
    if (game == null || game.isFinished || _state.isEnded) {
      return _notInProgress(game);
    }
    if (!dart.isValid) return Rejected('No such dart: $dart');
    return _record(DartThrown(dart));
  }

  /// Whether there is an input of the current game to take back.
  bool get canUndo => switch (_journal.events.lastOrNull) {
    VisitTotalSubmitted() || DartThrown() => true,
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
