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
    DartThrown(:final dart) => state.replaceCurrentGame(
      _dartThrown(state.game!, dart),
    ),
    VisitEnded() => state.replaceCurrentGame(_visitEnded(state.game!)),
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

/// Adds [dart] to the active player's visit: what it scores is each
/// game's business, as is what ends the visit before its last dart.
Game _dartThrown(Game game, Dart dart) => switch (game) {
  X01Game() => _x01Dart(game, dart),
  CricketGame() => _cricketDart(game, dart),
  ShanghaiGame() => _shanghaiDart(game, dart),
  KillerGame() => _killerDart(game, dart),
};

/// Fills the visit with misses until the turn passes (or the game ends).
Game _visitEnded(Game game) {
  final visits = game.visitsPlayed;
  var next = game;
  while (!next.isFinished && next.visitsPlayed == visits) {
    next = _dartThrown(next, Dart.miss);
  }
  return next;
}

/// Whether a visit of [darts] has had its last dart.
bool _isFull(List<Dart> darts) => darts.length >= dartsPerVisit;

// Each game below is rebuilt through its `_next`: the visit is over unless
// `dartsInVisit` is given, and whatever is not given stays as it was.

extension on X01Game {
  X01Game _next({
    List<PlayerScore>? scores,
    int? activeIndex,
    List<Dart> dartsInVisit = const [],
    Player? winner,
  }) => X01Game(
    config: config,
    scores: List.unmodifiable(scores ?? this.scores),
    activeIndex: activeIndex ?? this.activeIndex,
    dartsInVisit: List.unmodifiable(dartsInVisit),
    winner: winner,
  );
}

extension on CricketGame {
  CricketGame _next({
    List<CricketScore>? scores,
    int? activeIndex,
    List<Dart> dartsInVisit = const [],
    Player? winner,
  }) => CricketGame(
    config: config,
    scores: List.unmodifiable(scores ?? this.scores),
    activeIndex: activeIndex ?? this.activeIndex,
    dartsInVisit: List.unmodifiable(dartsInVisit),
    winner: winner,
  );
}

extension on ShanghaiGame {
  ShanghaiGame _next({
    List<ShanghaiScore>? scores,
    int? activeIndex,
    int? numberIndex,
    int? visitsPlayed,
    List<Dart> dartsInVisit = const [],
    Player? winner,
  }) => ShanghaiGame(
    config: config,
    scores: List.unmodifiable(scores ?? this.scores),
    activeIndex: activeIndex ?? this.activeIndex,
    numberIndex: numberIndex ?? this.numberIndex,
    visitsPlayed: visitsPlayed ?? this.visitsPlayed,
    dartsInVisit: List.unmodifiable(dartsInVisit),
    winner: winner,
  );
}

extension on KillerGame {
  KillerGame _next({
    List<KillerScore>? scores,
    int? activeIndex,
    KillerPhase? phase,
    int? visitsPlayed,
    List<Dart> dartsInVisit = const [],
    Player? winner,
  }) => KillerGame(
    config: config,
    scores: List.unmodifiable(scores ?? this.scores),
    activeIndex: activeIndex ?? this.activeIndex,
    phase: phase ?? this.phase,
    visitsPlayed: visitsPlayed ?? this.visitsPlayed,
    dartsInVisit: List.unmodifiable(dartsInVisit),
    winner: winner,
  );
}

X01Game _visitTotal(X01Game game, int score, int darts) {
  final after = game.activeScore.remaining - score;
  return _x01CompleteVisit(
    game,
    Visit(
      score: score,
      darts: darts,
      isBust: game.config.outRule.bustsOn(after),
    ),
  );
}

/// The X01 visit ends on a bust, a checkout or the last dart.
X01Game _x01Dart(X01Game game, Dart dart) {
  final darts = [...game.dartsInVisit, dart];
  final after = game.activeRemaining - dart.score;
  final outRule = game.config.outRule;
  final isBust =
      outRule.bustsOn(after) || (after == 0 && !outRule.allowsFinishOn(dart));
  if (!isBust && after != 0 && !_isFull(darts)) {
    return game._next(dartsInVisit: darts);
  }
  return _x01CompleteVisit(
    game,
    Visit(
      score: game.dartsInVisitScore + dart.score,
      darts: darts.length,
      isBust: isBust,
    ),
  );
}

X01Game _x01CompleteVisit(X01Game game, Visit visit) {
  final current = game.activeScore;
  final updated = current.after(visit);
  final won = updated.remaining == 0;
  return game._next(
    scores: [...game.scores]..[game.activeIndex] = updated,
    activeIndex: won ? game.activeIndex : game.nextIndex,
    winner: won ? current.player : null,
  );
}

/// The cricket visit ends on its third dart or as soon as the thrower
/// wins.
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
  if (!won && !_isFull(darts)) {
    return game._next(scores: scores, dartsInVisit: darts);
  }
  scores[game.activeIndex] = active.copyWith(
    visitsPlayed: active.visitsPlayed + 1,
  );
  return game._next(
    scores: scores,
    activeIndex: won ? game.activeIndex : game.nextIndex,
    winner: won ? active.player : null,
  );
}

/// The Shanghai visit ends on its third dart, or wins at once on a
/// single, a double and a treble of the number.
ShanghaiGame _shanghaiDart(ShanghaiGame game, Dart dart) {
  final darts = [...game.dartsInVisit, dart];
  final number = game.currentNumber;
  final hit = dart.sector == number ? dart.score : 0;
  final scores = [...game.scores];
  scores[game.activeIndex] = game.activeScore.copyWith(
    points: game.activeScore.points + hit,
  );

  if (game.config.instantShanghai && _isShanghai(darts, number)) {
    return game._next(
      scores: scores,
      visitsPlayed: game.visitsPlayed + 1,
      winner: game.activePlayer,
    );
  }
  if (!_isFull(darts)) return game._next(scores: scores, dartsInVisit: darts);
  return _shanghaiCompleteVisit(game._next(scores: scores));
}

bool _isShanghai(List<Dart> darts, int number) {
  final multipliers = {
    for (final d in darts)
      if (d.sector == number) d.multiplier,
  };
  return multipliers.containsAll({1, 2, 3});
}

/// Passes the turn; once everyone has thrown at the number, moves on to
/// the next one, or ends the game on the last.
ShanghaiGame _shanghaiCompleteVisit(ShanghaiGame game) {
  final roundIsOver = game.nextIndex == 0;
  final wasLastNumber =
      game.numberIndex + 1 >= game.config.length.numbers.length;
  if (roundIsOver && wasLastNumber) {
    return game._next(
      visitsPlayed: game.visitsPlayed + 1,
      winner: _shanghaiLeader(game.scores),
    );
  }
  return game._next(
    activeIndex: game.nextIndex,
    numberIndex: game.numberIndex + (roundIsOver ? 1 : 0),
    visitsPlayed: game.visitsPlayed + 1,
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
  final nextUnassigned = scores.indexWhere((s) => !s.hasNumber);
  return nextUnassigned == -1
      ? game._next(scores: scores, activeIndex: 0, phase: KillerPhase.playing)
      : game._next(scores: scores, activeIndex: nextUnassigned);
}

/// The Killer visit ends on its third dart, or with the game as soon as
/// a single player is left alive.
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
    return game._next(
      scores: scores,
      activeIndex: alive.single,
      phase: KillerPhase.finished,
      visitsPlayed: game.visitsPlayed + 1,
      winner: scores[alive.single].player,
    );
  }
  if (!_isFull(darts)) return game._next(scores: scores, dartsInVisit: darts);
  return _killerCompleteVisit(game._next(scores: scores));
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

/// Passes the turn to the next player still alive.
KillerGame _killerCompleteVisit(KillerGame game) {
  final n = game.scores.length;
  var next = game.nextIndex;
  for (var i = 0; i < n; i++) {
    if (!game.scores[next].isOut) break;
    next = (next + 1) % n;
  }
  return game._next(activeIndex: next, visitsPlayed: game.visitsPlayed + 1);
}
