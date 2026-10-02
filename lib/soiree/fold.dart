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
    VisitTotalSubmitted(:final score) => SoireeState(
      game: _applyVisit(state.game!, score),
    ),
  };
}

GameState _applyVisit(GameState game, int score) {
  final current = game.activeScore;
  // Straight-out: going below zero scores nothing (bust rules: ticket 03).
  final scored = current.remaining - score < 0 ? 0 : score;
  final updated = PlayerScore(
    player: current.player,
    remaining: current.remaining - scored,
    lastVisit: scored,
  );
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
