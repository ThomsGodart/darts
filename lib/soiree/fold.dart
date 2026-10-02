import 'events.dart';
import 'state.dart';

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
      game: _applyVisit(state.game!, score, darts),
    ),
  };
}

GameState _applyVisit(GameState game, int score, int darts) {
  final current = game.activeScore;
  final visit = Visit(
    score: score,
    darts: darts,
    isBust: game.config.outRule.bustsOn(current.remaining - score),
  );
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
