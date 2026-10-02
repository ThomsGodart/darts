import 'dart.dart';
import 'events.dart';
import 'state.dart';
import 'x01_config.dart';

/// Rebuilds the state from scratch by replaying [events].
SoireeState foldEvents(Iterable<SoireeEvent> events) =>
    events.fold(const SoireeState(), applyEvent);

SoireeState applyEvent(SoireeState state, SoireeEvent event) {
  return switch (event) {
    GameStarted(:final players, :final config) => SoireeState(
      game: GameState(
        config: config,
        scores: [
          for (final player in players)
            PlayerScore(player: player, remaining: config.startScore),
        ],
        activeIndex: 0,
      ),
    ),
    VisitTotalSubmitted(:final score, :final darts) => SoireeState(
      game: _visitTotal(state.game!, score, darts),
    ),
    DartThrown(:final dart) => SoireeState(
      game: _dartThrown(state.game!, dart),
    ),
  };
}

GameState _visitTotal(GameState game, int score, int darts) {
  final after = game.activeScore.remaining - score;
  return _completeVisit(
    game,
    Visit(
      score: score,
      darts: darts,
      isBust: game.config.outRule.bustsOn(after),
    ),
  );
}

/// Adds [dart] to the visit, which ends on a bust, a checkout or the
/// last dart.
GameState _dartThrown(GameState game, Dart dart) {
  final darts = [...game.dartsInVisit, dart];
  final after = game.activeRemaining - dart.score;
  final outRule = game.config.outRule;
  final isBust =
      outRule.bustsOn(after) || (after == 0 && !outRule.allowsFinishOn(dart));
  if (!isBust && after != 0 && darts.length < dartsPerVisit) {
    return GameState(
      config: game.config,
      scores: game.scores,
      activeIndex: game.activeIndex,
      dartsInVisit: List.unmodifiable(darts),
    );
  }
  return _completeVisit(
    game,
    Visit(
      score: game.dartsInVisitScore + dart.score,
      darts: darts.length,
      isBust: isBust,
    ),
  );
}

GameState _completeVisit(GameState game, Visit visit) {
  final current = game.activeScore;
  final updated = current.after(visit);
  final scores = [...game.scores]..[game.activeIndex] = updated;
  final won = updated.remaining == 0;
  return GameState(
    config: game.config,
    scores: scores,
    activeIndex: won
        ? game.activeIndex
        : (game.activeIndex + 1) % scores.length,
    winner: won ? current.player : null,
  );
}
