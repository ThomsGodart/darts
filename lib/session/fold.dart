import 'dart.dart';
import 'events.dart';
import 'player.dart';
import 'state.dart';
import 'game_config.dart';

/// Rebuilds the state from scratch by replaying [events].
SessionState foldEvents(Iterable<SessionEvent> events) =>
    events.fold(const SessionState(), applyEvent);

SessionState applyEvent(SessionState state, SessionEvent event) {
  return switch (event) {
    GameStarted(:final players, :final config) => state.addGame(
      _newGame(players, config),
    ),
    VisitTotalSubmitted(:final score, :final darts) => state.replaceCurrentGame(
      _visitTotal(state.game! as X01Game, score, darts),
    ),
    DartThrown(:final dart) => state.replaceCurrentGame(switch (state.game!) {
      final X01Game game => _dartThrown(game, dart),
    }),
    SessionEnded() => SessionState(games: state.games, isEnded: true),
  };
}

Game _newGame(List<Player> players, GameConfig config) => switch (config) {
  X01Config() => X01Game(
    config: config,
    scores: [
      for (final player in players)
        PlayerScore(player: player, remaining: config.startScore),
    ],
    activeIndex: 0,
  ),
};

X01Game _visitTotal(X01Game game, int score, int darts) {
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
X01Game _dartThrown(X01Game game, Dart dart) {
  final darts = [...game.dartsInVisit, dart];
  final after = game.activeRemaining - dart.score;
  final outRule = game.config.outRule;
  final isBust =
      outRule.bustsOn(after) || (after == 0 && !outRule.allowsFinishOn(dart));
  if (!isBust && after != 0 && darts.length < dartsPerVisit) {
    return X01Game(
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

X01Game _completeVisit(X01Game game, Visit visit) {
  final current = game.activeScore;
  final updated = current.after(visit);
  final scores = [...game.scores]..[game.activeIndex] = updated;
  final won = updated.remaining == 0;
  return X01Game(
    config: game.config,
    scores: scores,
    activeIndex: won
        ? game.activeIndex
        : (game.activeIndex + 1) % scores.length,
    winner: won ? current.player : null,
  );
}
