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
      final CricketGame game => _cricketDart(game, dart),
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
  CricketConfig() => CricketGame(
    config: config,
    scores: [for (final player in players) CricketScore(player: player)],
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

/// Adds [dart] to the cricket visit, which ends on its third dart or as
/// soon as the thrower wins.
CricketGame _cricketDart(CricketGame game, Dart dart) {
  final darts = [...game.dartsInVisit, dart];
  final scores = [...game.scores];
  if (dart.cricketMarks case (:final number, :final marks)) {
    final thrower = scores[game.activeIndex];
    final before = thrower.marksOn(number);
    final closing = (marksToClose - before).clamp(0, marks);
    final extra = marks - closing;
    final othersOpen = [
      for (final (i, s) in scores.indexed)
        if (i != game.activeIndex && !s.isClosed(number)) i,
    ];
    scores[game.activeIndex] = thrower.copyWith(
      marks: {...thrower.marks, number: before + closing},
      marksHit: thrower.marksHit + marks,
    );
    final points = extra * number;
    if (points > 0 && othersOpen.isNotEmpty) {
      switch (game.config.variant) {
        case CricketVariant.standard:
          final t = scores[game.activeIndex];
          scores[game.activeIndex] = t.copyWith(points: t.points + points);
        case CricketVariant.cutThroat:
          for (final i in othersOpen) {
            scores[i] = scores[i].copyWith(points: scores[i].points + points);
          }
      }
    }
  }
  final active = scores[game.activeIndex];
  final won =
      active.hasClosedAll &&
      switch (game.config.variant) {
        CricketVariant.standard => scores.every(
          (s) => s.points <= active.points,
        ),
        CricketVariant.cutThroat => scores.every(
          (s) => s.points >= active.points,
        ),
      };
  if (!won && darts.length < dartsPerVisit) {
    return CricketGame(
      config: game.config,
      scores: List.unmodifiable(scores),
      activeIndex: game.activeIndex,
      dartsInVisit: List.unmodifiable(darts),
    );
  }
  scores[game.activeIndex] = active.copyWith(
    visitsPlayed: active.visitsPlayed + 1,
  );
  return CricketGame(
    config: game.config,
    scores: List.unmodifiable(scores),
    activeIndex: won
        ? game.activeIndex
        : (game.activeIndex + 1) % scores.length,
    winner: won ? active.player : null,
  );
}
