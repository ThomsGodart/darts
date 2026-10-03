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
      switch (state.game) {
        final X01Game game => _visitTotal(game, score, darts),
        _ => throw const FormatException('A visit total outside an X01 game'),
      },
    ),
    DartThrown(:final dart) => state.replaceCurrentGame(switch (state.game!) {
      final X01Game game => _dartThrown(game, dart),
      final CricketGame game => _cricketDart(game, dart),
      final ShanghaiGame game => _shanghaiDart(game, dart),
      final KillerGame game => _killerDart(game, dart),
    }),
    NumberAssigned(:final sector) => state.replaceCurrentGame(
      switch (state.game) {
        final KillerGame game => _assignNumber(game, sector),
        _ => throw const FormatException('A number outside a Killer game'),
      },
    ),
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
  ShanghaiConfig() => ShanghaiGame(
    config: config,
    scores: [for (final player in players) ShanghaiScore(player: player)],
    activeIndex: 0,
  ),
  KillerConfig() => KillerGame(
    config: config,
    scores: [
      for (final player in players)
        KillerScore(player: player, lives: config.lives),
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
      final scorers = game.config.variant.scoresForThrower
          ? [game.activeIndex]
          : othersOpen;
      for (final i in scorers) {
        scores[i] = scores[i].copyWith(points: scores[i].points + points);
      }
    }
  }
  final active = scores[game.activeIndex];
  final won =
      active.hasClosedAll &&
      game.config.variant.wins(active.points, [
        for (final s in scores) s.points,
      ]);
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

ShanghaiGame _shanghaiDart(ShanghaiGame game, Dart dart) {
  final darts = [...game.dartsInVisit, dart];
  final number = game.currentNumber;
  final hit = dart.sector == number ? dart.score : 0;
  final points = game.activeScore.points + hit;
  final scores = [...game.scores];
  scores[game.activeIndex] = game.activeScore.copyWith(points: points);

  final shanghai = game.config.instantShanghai && _isShanghai(darts, number);
  if (shanghai) {
    return ShanghaiGame(
      config: game.config,
      scores: List.unmodifiable(scores),
      activeIndex: game.activeIndex,
      numberIndex: game.numberIndex,
      visitsPlayed: game.visitsPlayed + 1,
      winner: game.activePlayer,
    );
  }
  if (darts.length < dartsPerVisit) {
    return ShanghaiGame(
      config: game.config,
      scores: List.unmodifiable(scores),
      activeIndex: game.activeIndex,
      numberIndex: game.numberIndex,
      visitsPlayed: game.visitsPlayed,
      dartsInVisit: List.unmodifiable(darts),
    );
  }
  return _shanghaiCompleteVisit(
    ShanghaiGame(
      config: game.config,
      scores: List.unmodifiable(scores),
      activeIndex: game.activeIndex,
      numberIndex: game.numberIndex,
      visitsPlayed: game.visitsPlayed,
    ),
  );
}

bool _isShanghai(List<Dart> darts, int number) {
  final multipliers = {
    for (final d in darts)
      if (d.sector == number) d.multiplier,
  };
  return multipliers.containsAll({1, 2, 3});
}

ShanghaiGame _shanghaiCompleteVisit(ShanghaiGame game) {
  final nextIndex = (game.activeIndex + 1) % game.scores.length;
  var numberIndex = game.numberIndex;
  Player? winner;
  if (nextIndex == 0) {
    if (numberIndex + 1 >= game.config.length.numbers.length) {
      winner = _shanghaiLeader(game.scores);
    } else {
      numberIndex += 1;
    }
  }
  return ShanghaiGame(
    config: game.config,
    scores: game.scores,
    activeIndex: winner != null ? game.activeIndex : nextIndex,
    numberIndex: numberIndex,
    visitsPlayed: game.visitsPlayed + 1,
    winner: winner,
  );
}

Player _shanghaiLeader(List<ShanghaiScore> scores) {
  var best = scores.first;
  for (final s in scores.skip(1)) {
    if (s.points > best.points) best = s;
  }
  return best.player;
}

KillerGame _assignNumber(KillerGame game, int sector) {
  if (game.phase != KillerPhase.assigning) {
    throw const FormatException('Numbers are only assigned while assigning');
  }
  if (game.takenNumbers.contains(sector)) {
    throw const FormatException('That number is already taken');
  }
  final scores = [...game.scores];
  scores[game.activeIndex] = game.activeScore.copyWith(number: sector);
  final nextUnassigned = [
    for (final (i, s) in scores.indexed)
      if (!s.hasNumber) i,
  ];
  if (nextUnassigned.isEmpty) {
    return KillerGame(
      config: game.config,
      scores: List.unmodifiable(scores),
      activeIndex: 0,
      phase: KillerPhase.playing,
    );
  }
  return KillerGame(
    config: game.config,
    scores: List.unmodifiable(scores),
    activeIndex: nextUnassigned.first,
    phase: KillerPhase.assigning,
  );
}

KillerGame _killerDart(KillerGame game, Dart dart) {
  if (game.phase != KillerPhase.playing) {
    throw const FormatException('Darts are only thrown while playing');
  }
  final darts = [...game.dartsInVisit, dart];
  var scores = [...game.scores];
  if (dart.isDouble && dart.sector >= 1 && dart.sector <= 20) {
    scores = _applyKillerDouble(game, scores, dart.sector);
  }
  final alive = [
    for (final (i, s) in scores.indexed)
      if (!s.isOut) i,
  ];
  if (alive.length == 1) {
    return KillerGame(
      config: game.config,
      scores: List.unmodifiable(scores),
      activeIndex: alive.single,
      phase: KillerPhase.finished,
      visitsPlayed: game.visitsPlayed + 1,
      winner: scores[alive.single].player,
    );
  }
  if (darts.length < dartsPerVisit) {
    return KillerGame(
      config: game.config,
      scores: List.unmodifiable(scores),
      activeIndex: game.activeIndex,
      phase: KillerPhase.playing,
      visitsPlayed: game.visitsPlayed,
      dartsInVisit: List.unmodifiable(darts),
    );
  }
  return _killerCompleteVisit(
    KillerGame(
      config: game.config,
      scores: List.unmodifiable(scores),
      activeIndex: game.activeIndex,
      phase: KillerPhase.playing,
      visitsPlayed: game.visitsPlayed,
    ),
  );
}

List<KillerScore> _applyKillerDouble(
  KillerGame game,
  List<KillerScore> scores,
  int sector,
) {
  final thrower = scores[game.activeIndex];
  final targetIndex = scores.indexWhere((s) => s.number == sector);
  if (targetIndex == -1) return scores;
  final target = scores[targetIndex];
  if (target.isOut) return scores;

  if (targetIndex == game.activeIndex) {
    if (!thrower.isKiller) {
      final progress = thrower.killerProgress + 1;
      final becomes = progress >= game.config.doublesToKiller;
      scores[targetIndex] = thrower.copyWith(
        killerProgress: progress,
        isKiller: becomes || thrower.isKiller,
      );
    } else {
      final lives = (thrower.lives ?? 0) - 1;
      scores[targetIndex] = thrower.copyWith(
        lives: lives,
        isKiller: lives > 0 && thrower.isKiller,
      );
    }
    return scores;
  }

  if (!thrower.isKiller) return scores;
  final lives = (target.lives ?? 0) - 1;
  scores[targetIndex] = target.copyWith(
    lives: lives,
    isKiller: lives > 0 && target.isKiller,
  );
  return scores;
}

KillerGame _killerCompleteVisit(KillerGame game) {
  final n = game.scores.length;
  var next = (game.activeIndex + 1) % n;
  for (var i = 0; i < n; i++) {
    if (!game.scores[next].isOut) break;
    next = (next + 1) % n;
  }
  final alive = [
    for (final s in game.scores)
      if (!s.isOut) s,
  ];
  if (alive.length == 1) {
    return KillerGame(
      config: game.config,
      scores: game.scores,
      activeIndex: game.scores.indexWhere(
        (s) => s.player.id == alive.single.player.id,
      ),
      phase: KillerPhase.finished,
      visitsPlayed: game.visitsPlayed + 1,
      winner: alive.single.player,
    );
  }
  return KillerGame(
    config: game.config,
    scores: game.scores,
    activeIndex: next,
    phase: KillerPhase.playing,
    visitsPlayed: game.visitsPlayed + 1,
  );
}
