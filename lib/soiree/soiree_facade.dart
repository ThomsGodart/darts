import 'commands.dart';
import 'dart.dart';
import 'events.dart';
import 'fold.dart';
import 'journal.dart';
import 'player.dart';
import 'state.dart';
import 'x01_config.dart';
import 'x01_rules.dart';

/// Single entry point to the soirée domain.
///
/// Commands are validated against the current state; accepted ones are
/// appended to the [SoireeJournal] and folded into a new [state].
class Soiree {
  Soiree(this._journal) : _state = foldEvents(_journal.events);

  final SoireeJournal _journal;
  SoireeState _state;

  SoireeState get state => _state;

  CommandResult startGame(
    List<Player> players, {
    X01Config config = const X01Config(),
  }) {
    if (players.isEmpty) return const Rejected('A game needs players');
    if (players.length > maxPlayers) {
      return const Rejected('At most $maxPlayers players');
    }
    if (players.map((p) => p.id).toSet().length != players.length) {
      return const Rejected('A player cannot play twice in a game');
    }
    if (!config.isValid) {
      return Rejected('Invalid start score ${config.startScore}');
    }
    final game = _state.game;
    if (game != null && !game.isFinished) {
      return const Rejected('A game is already in progress');
    }
    return _record(
      GameStarted(players: List.unmodifiable(players), config: config),
    );
  }

  /// Submits a visit by its total. When it brings the remaining score to
  /// exactly 0, [dartsAtCheckout] must say how many darts it took (one of
  /// [GameState.checkoutDartOptions]); otherwise it must be omitted.
  CommandResult submitVisitTotal(int score, {int? dartsAtCheckout}) {
    final game = _state.game;
    if (game == null || game.isFinished) return _notInProgress(game);
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
    if (game == null || game.isFinished) return _notInProgress(game);
    if (!dart.isValid) return Rejected('No such dart: $dart');
    return _record(DartThrown(dart));
  }

  /// Whether there is an input of the current game to take back.
  bool get canUndo => switch (_journal.events.lastOrNull) {
    VisitTotalSubmitted() || DartThrown() => true,
    GameStarted() || null => false,
  };

  /// Takes back the latest input, even after the game was won.
  CommandResult undo() {
    if (!canUndo) return const Rejected('Nothing to undo');
    _journal.removeLast();
    _state = foldEvents(_journal.events);
    return const Accepted();
  }

  /// Why no input can be entered into [game] (missing or finished).
  Rejected _notInProgress(GameState? game) => game == null
      ? const Rejected('No game in progress')
      : const Rejected('The game is over');

  CommandResult _record(SoireeEvent event) {
    _journal.append(event);
    _state = applyEvent(_state, event);
    return const Accepted();
  }
}
