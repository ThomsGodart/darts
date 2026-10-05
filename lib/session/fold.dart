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
    GameStarted(:final players, :final config, :final confirmsVisits) =>
      state.addGame(_newGame(players, config), confirmsVisits: confirmsVisits),
    VisitTotalSubmitted(
      :final score,
      :final darts,
      :final dartsAtDouble,
      :final isBust,
    ) =>
      state.replaceCurrentGame(switch (state.game) {
        final X01Game game => _visitTotal(
          game,
          score,
          darts,
          dartsAtDouble,
          isBust: isBust,
        ),
        final CountUpGame game => _countUpCompleteVisit(game, score),
        _ => throw const FormatException(
          'A visit total in a game entered dart by dart',
        ),
      }),
    DartThrown(:final dart) => state.replaceCurrentGame(
      _dartThrown(state.game!, dart, confirms: state.confirmsVisits),
    ),
    VisitEnded() => state.replaceCurrentGame(_visitEnded(state.game!)),
    NumberAssigned(:final sector) => state.replaceCurrentGame(
      switch (state.game) {
        final KillerGame game => _assignNumber(game, sector),
        _ => throw const FormatException('A number outside a Killer game'),
      },
    ),
    SessionEnded() => SessionState(
      games: state.games,
      isEnded: true,
      confirmsVisits: state.confirmsVisits,
    ),
  };
}

Game _newGame(List<Player> players, GameConfig config) => switch (config) {
  X01Config() => X01Game(
    config: config,
    scores: [
      for (final player in players)
        PlayerScore(
          player: player,
          remaining: config.startScore,
          isIn: !config.doubleIn,
        ),
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
  HalveItConfig() => HalveItGame(
    config: config,
    scores: [
      for (final player in players)
        HalveItScore(player: player, points: halveItStartScore),
    ],
    activeIndex: 0,
  ),
  GolfConfig() => GolfGame(
    config: config,
    scores: [for (final player in players) GolfScore(player: player)],
    activeIndex: 0,
  ),
  AroundTheClockConfig() => AroundTheClockGame(
    config: config,
    scores: [for (final player in players) AroundTheClockScore(player: player)],
    activeIndex: 0,
  ),
  Bobs27Config() => Bobs27Game(
    config: config,
    scores: [
      for (final player in players)
        Bobs27Score(player: player, points: bobs27StartScore),
    ],
    activeIndex: 0,
  ),
  CountUpConfig() => CountUpGame(
    config: config,
    scores: [for (final player in players) CountUpScore(player: player)],
    activeIndex: 0,
  ),
  BaseballConfig() => BaseballGame(
    config: config,
    scores: [for (final player in players) BaseballScore(player: player)],
    activeIndex: 0,
  ),
};

/// Adds [dart] to the active player's visit. A visit that has had its
/// last dart stays open until it is ended, for its thrower to read it;
/// unless [confirms] is false, as in the games journaled before visits
/// were confirmed, where the turn passes at once.
Game _dartThrown(Game game, Dart dart, {required bool confirms}) {
  if (game.visitIsOver) {
    throw const FormatException('A dart in a visit that is over');
  }
  final next = _addDart(game, dart);
  return confirms || next.isFinished || !next.visitIsOver
      ? next
      : _visitEnded(next);
}

/// What [dart] scores is each game's business, as is whether it wins the
/// game on the spot.
Game _addDart(Game game, Dart dart) => switch (game) {
  X01Game() => _x01Dart(game, dart),
  CricketGame() => _cricketDart(game, dart),
  ShanghaiGame() => _shanghaiDart(game, dart),
  KillerGame() => _killerDart(game, dart),
  HalveItGame() => _halveItDart(game, dart),
  GolfGame() => _golfDart(game, dart),
  AroundTheClockGame() => _aroundTheClockDart(game, dart),
  Bobs27Game() => _bobs27Dart(game, dart),
  CountUpGame() => _countUpDart(game, dart),
  BaseballGame() => _baseballDart(game, dart),
};

/// Ends the visit and passes the turn. In Golf the last dart thrown
/// stands; everywhere else the darts not thrown count as misses.
Game _visitEnded(Game game) => switch (game) {
  X01Game() => _x01EndVisit(game),
  CricketGame() => _cricketEndVisit(game),
  ShanghaiGame() => _shanghaiCompleteVisit(game),
  KillerGame() => _killerCompleteVisit(game),
  HalveItGame() => _halveItEndVisit(game),
  GolfGame() => _golfCompleteVisit(game, game.dartsInVisit),
  AroundTheClockGame() => game._next(
    activeIndex: game.nextIndex,
    visitsPlayed: game.visitsPlayed + 1,
  ),
  Bobs27Game() => _bobs27EndVisit(game),
  CountUpGame() => _countUpCompleteVisit(
    game,
    game.dartsInVisit.fold(0, (sum, d) => sum + d.score),
  ),
  BaseballGame() => _baseballEndVisit(game),
};

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

extension on HalveItGame {
  HalveItGame _next({
    List<HalveItScore>? scores,
    int? activeIndex,
    int? targetIndex,
    int? visitsPlayed,
    List<Dart> dartsInVisit = const [],
    Player? winner,
  }) => HalveItGame(
    config: config,
    scores: List.unmodifiable(scores ?? this.scores),
    activeIndex: activeIndex ?? this.activeIndex,
    targetIndex: targetIndex ?? this.targetIndex,
    visitsPlayed: visitsPlayed ?? this.visitsPlayed,
    dartsInVisit: List.unmodifiable(dartsInVisit),
    winner: winner,
  );
}

extension on GolfGame {
  GolfGame _next({
    List<GolfScore>? scores,
    int? activeIndex,
    int? holeIndex,
    int? visitsPlayed,
    List<Dart> dartsInVisit = const [],
    Player? winner,
  }) => GolfGame(
    config: config,
    scores: List.unmodifiable(scores ?? this.scores),
    activeIndex: activeIndex ?? this.activeIndex,
    holeIndex: holeIndex ?? this.holeIndex,
    visitsPlayed: visitsPlayed ?? this.visitsPlayed,
    dartsInVisit: List.unmodifiable(dartsInVisit),
    winner: winner,
  );
}

X01Game _visitTotal(
  X01Game game,
  int score,
  int darts,
  int? dartsAtDouble, {
  required bool isBust,
}) {
  final after = game.activeScore.remaining - score;
  return _x01CompleteVisit(
    game,
    Visit(
      score: score,
      darts: darts,
      isBust: isBust || game.config.outRule.bustsOn(after),
      dartsAtDouble: dartsAtDouble,
    ),
    // A total says nothing of the darts: scoring is taken as being in.
    isIn: game.activeScore.isIn || score > 0,
  );
}

/// A checkout wins the game on the spot; a bust waits to be read.
X01Game _x01Dart(X01Game game, Dart dart) {
  final next = game._next(dartsInVisit: [...game.dartsInVisit, dart]);
  return next.visitChecksOut ? _x01EndVisit(next) : next;
}

/// A bust or a checkout stops the visit on the dart that did it; any
/// other visit counts three darts.
X01Game _x01EndVisit(X01Game game) {
  final isBust = game.visitBusts;
  final darts = [
    ...game.dartsInVisit,
    if (!isBust && !game.visitChecksOut)
      for (var i = game.dartsInVisit.length; i < dartsPerVisit; i++) Dart.miss,
  ];
  return _x01CompleteVisit(
    game,
    Visit(
      score: game.countedScoreOf(darts),
      darts: darts.length,
      isBust: isBust,
      // Straight-out has no double to aim at: nothing to count.
      dartsAtDouble: game.config.outRule == OutRule.straight
          ? null
          : game.dartsAtDoubleIn(darts),
      thrown: game.dartsInVisit,
    ),
    isIn: game.activeScore.isIn || darts.any((d) => d.isDouble),
  );
}

X01Game _x01CompleteVisit(X01Game game, Visit visit, {required bool isIn}) {
  final current = game.activeScore;
  final updated = current.after(visit, isIn: isIn);
  final won = updated.remaining == 0;
  return game._next(
    scores: [...game.scores]..[game.activeIndex] = updated,
    activeIndex: won ? game.activeIndex : game.nextIndex,
    winner: won ? current.player : null,
  );
}

/// A cricket dart marks the board at once, and ends the game as soon as
/// the thrower wins.
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
  if (!won) return game._next(scores: scores, dartsInVisit: darts);
  scores[game.activeIndex] = active.copyWith(
    visitsPlayed: active.visitsPlayed + 1,
  );
  return game._next(scores: scores, winner: active.player);
}

CricketGame _cricketEndVisit(CricketGame game) {
  final active = game.activeScore;
  return game._next(
    scores: [...game.scores]
      ..[game.activeIndex] = active.copyWith(
        visitsPlayed: active.visitsPlayed + 1,
      ),
    activeIndex: game.nextIndex,
  );
}

/// A Shanghai dart scores at once, and wins at once on a single, a double
/// and a treble of the number.
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
  return game._next(scores: scores, dartsInVisit: darts);
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
      winner: _firstBest(game.scores, (a, b) => a.points > b.points).player,
    );
  }
  return game._next(
    activeIndex: game.nextIndex,
    numberIndex: game.numberIndex + (roundIsOver ? 1 : 0),
    visitsPlayed: game.visitsPlayed + 1,
  );
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

/// A Killer dart takes its life at once, and ends the game as soon as a
/// single player is left alive.
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
  return game._next(scores: scores, dartsInVisit: darts);
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

HalveItGame _halveItDart(HalveItGame game, Dart dart) =>
    game._next(dartsInVisit: [...game.dartsInVisit, dart]);

/// The hits of a Halve-It visit add up, and a visit without one halves
/// the score, rounding up.
HalveItGame _halveItEndVisit(HalveItGame game) {
  final darts = game.dartsInVisit;
  final target = game.currentTarget;
  final hit = darts.fold(0, (sum, d) => sum + target.scoreOf(d));
  final before = game.activeScore;
  final scores = [...game.scores];
  scores[game.activeIndex] = HalveItScore(
    player: before.player,
    points: hit == 0 ? (before.points / 2).ceil() : before.points + hit,
    wasHalved: hit == 0,
  );

  final roundIsOver = game.nextIndex == 0;
  final wasLastTarget = game.targetIndex + 1 >= halveItTargets.length;
  if (roundIsOver && wasLastTarget) {
    return game._next(
      scores: scores,
      visitsPlayed: game.visitsPlayed + 1,
      winner: _firstBest(scores, (a, b) => a.points > b.points).player,
    );
  }
  return game._next(
    scores: scores,
    activeIndex: game.nextIndex,
    targetIndex: game.targetIndex + (roundIsOver ? 1 : 0),
    visitsPlayed: game.visitsPlayed + 1,
  );
}

GolfGame _golfDart(GolfGame game, Dart dart) =>
    game._next(dartsInVisit: [...game.dartsInVisit, dart]);

/// Writes the hole on the active player's card from the last of [darts],
/// then passes the turn; once everyone has played the hole, moves on to
/// the next one, or ends the game on the last.
GolfGame _golfCompleteVisit(GolfGame game, List<Dart> darts) {
  final before = game.activeScore;
  final scores = [...game.scores];
  scores[game.activeIndex] = GolfScore(
    player: before.player,
    holeStrokes: List.unmodifiable([
      ...before.holeStrokes,
      golfStrokes(darts.lastOrNull, hole: game.currentHole),
    ]),
  );

  final roundIsOver = game.nextIndex == 0;
  final wasLastHole = game.currentHole >= game.config.holes;
  if (roundIsOver && wasLastHole) {
    return game._next(
      scores: scores,
      visitsPlayed: game.visitsPlayed + 1,
      winner: _firstBest(scores, (a, b) => a.strokes < b.strokes).player,
    );
  }
  return game._next(
    scores: scores,
    activeIndex: game.nextIndex,
    holeIndex: game.holeIndex + (roundIsOver ? 1 : 0),
    visitsPlayed: game.visitsPlayed + 1,
  );
}

/// The best of [scores] by [beats]; on a tie, whoever threw first.
T _firstBest<T>(List<T> scores, bool Function(T a, T b) beats) {
  var best = scores.first;
  for (final score in scores.skip(1)) {
    if (beats(score, best)) best = score;
  }
  return best;
}

extension on AroundTheClockGame {
  AroundTheClockGame _next({
    List<AroundTheClockScore>? scores,
    int? activeIndex,
    int? visitsPlayed,
    List<Dart> dartsInVisit = const [],
    Player? winner,
  }) => AroundTheClockGame(
    config: config,
    scores: List.unmodifiable(scores ?? this.scores),
    activeIndex: activeIndex ?? this.activeIndex,
    visitsPlayed: visitsPlayed ?? this.visitsPlayed,
    dartsInVisit: List.unmodifiable(dartsInVisit),
    winner: winner,
  );
}

extension on Bobs27Game {
  Bobs27Game _next({
    List<Bobs27Score>? scores,
    int? activeIndex,
    int? targetIndex,
    int? visitsPlayed,
    List<Dart> dartsInVisit = const [],
    Player? winner,
  }) => Bobs27Game(
    config: config,
    scores: List.unmodifiable(scores ?? this.scores),
    activeIndex: activeIndex ?? this.activeIndex,
    targetIndex: targetIndex ?? this.targetIndex,
    visitsPlayed: visitsPlayed ?? this.visitsPlayed,
    dartsInVisit: List.unmodifiable(dartsInVisit),
    winner: winner,
  );
}

extension on CountUpGame {
  CountUpGame _next({
    List<CountUpScore>? scores,
    int? activeIndex,
    int? roundIndex,
    int? visitsPlayed,
    List<Dart> dartsInVisit = const [],
    Player? winner,
  }) => CountUpGame(
    config: config,
    scores: List.unmodifiable(scores ?? this.scores),
    activeIndex: activeIndex ?? this.activeIndex,
    roundIndex: roundIndex ?? this.roundIndex,
    visitsPlayed: visitsPlayed ?? this.visitsPlayed,
    dartsInVisit: List.unmodifiable(dartsInVisit),
    winner: winner,
  );
}

extension on BaseballGame {
  BaseballGame _next({
    List<BaseballScore>? scores,
    int? activeIndex,
    int? inningIndex,
    int? visitsPlayed,
    List<Dart> dartsInVisit = const [],
    Player? winner,
  }) => BaseballGame(
    config: config,
    scores: List.unmodifiable(scores ?? this.scores),
    activeIndex: activeIndex ?? this.activeIndex,
    inningIndex: inningIndex ?? this.inningIndex,
    visitsPlayed: visitsPlayed ?? this.visitsPlayed,
    dartsInVisit: List.unmodifiable(dartsInVisit),
    winner: winner,
  );
}

/// Each dart on the thrower's number moves them to the next one; hitting
/// the last one wins at once.
AroundTheClockGame _aroundTheClockDart(AroundTheClockGame game, Dart dart) {
  final darts = [...game.dartsInVisit, dart];
  final before = game.activeScore;
  final scores = [...game.scores];
  if (dart.sector == game.activeTarget) {
    scores[game.activeIndex] = AroundTheClockScore(
      player: before.player,
      hits: before.hits + 1,
    );
  }
  if (scores[game.activeIndex].hits >= game.config.targets) {
    return game._next(
      scores: scores,
      visitsPlayed: game.visitsPlayed + 1,
      winner: before.player,
    );
  }
  return game._next(scores: scores, dartsInVisit: darts);
}

Bobs27Game _bobs27Dart(Bobs27Game game, Dart dart) =>
    game._next(dartsInVisit: [...game.dartsInVisit, dart]);

/// Each hit of a Bob's 27 visit on the target adds its value, a visit
/// without one takes it away, and a player down to zero or less is out.
Bobs27Game _bobs27EndVisit(Bobs27Game game) {
  final darts = game.dartsInVisit;
  final target = game.currentTarget;
  final hits = darts.where((d) => d == target).length;
  final before = game.activeScore;
  final scores = [...game.scores];
  scores[game.activeIndex] = Bobs27Score(
    player: before.player,
    points: hits == 0
        ? before.points - target.score
        : before.points + hits * target.score,
  );

  // Whoever throws next among the players still in, if any.
  final n = scores.length;
  int? nextIn;
  for (var step = 1; step <= n; step++) {
    final i = (game.activeIndex + step) % n;
    if (!scores[i].isOut) {
      nextIn = i;
      break;
    }
  }
  if (nextIn == null) {
    // Everyone is out: whoever lasted longest, the last to fall, wins.
    return game._next(
      scores: scores,
      visitsPlayed: game.visitsPlayed + 1,
      winner: before.player,
    );
  }
  final roundIsOver = nextIn <= game.activeIndex;
  final wasLastTarget = game.targetIndex + 1 >= bobs27Targets.length;
  if (roundIsOver && wasLastTarget) {
    return game._next(
      scores: scores,
      visitsPlayed: game.visitsPlayed + 1,
      winner: _firstBest(scores, (a, b) => a.points > b.points).player,
    );
  }
  return game._next(
    scores: scores,
    activeIndex: nextIn,
    targetIndex: game.targetIndex + (roundIsOver ? 1 : 0),
    visitsPlayed: game.visitsPlayed + 1,
  );
}

CountUpGame _countUpDart(CountUpGame game, Dart dart) =>
    game._next(dartsInVisit: [...game.dartsInVisit, dart]);

/// Adds a visit of [points], then passes the turn; once everyone has
/// thrown the round, moves on to the next one, or ends the game on the
/// last.
CountUpGame _countUpCompleteVisit(CountUpGame game, int points) {
  final before = game.activeScore;
  final scores = [...game.scores];
  scores[game.activeIndex] = CountUpScore(
    player: before.player,
    points: before.points + points,
  );
  final roundIsOver = game.nextIndex == 0;
  if (roundIsOver && game.round >= game.config.rounds) {
    return game._next(
      scores: scores,
      visitsPlayed: game.visitsPlayed + 1,
      winner: _firstBest(scores, (a, b) => a.points > b.points).player,
    );
  }
  return game._next(
    scores: scores,
    activeIndex: game.nextIndex,
    roundIndex: game.roundIndex + (roundIsOver ? 1 : 0),
    visitsPlayed: game.visitsPlayed + 1,
  );
}

/// A Baseball dart scores its runs at once.
BaseballGame _baseballDart(BaseballGame game, Dart dart) {
  final before = game.activeScore;
  return game._next(
    scores: [...game.scores]
      ..[game.activeIndex] = BaseballScore(
        player: before.player,
        runs: before.runs + game.runsOf(dart),
      ),
    dartsInVisit: [...game.dartsInVisit, dart],
  );
}

/// After the ninth inning the most runs win; a tie for the lead plays
/// another inning, as long as the board has a number for it.
BaseballGame _baseballEndVisit(BaseballGame game) {
  final scores = game.scores;
  final roundIsOver = game.nextIndex == 0;
  if (roundIsOver && game.inning >= baseballInnings) {
    final leader = _firstBest(scores, (a, b) => a.runs > b.runs);
    final tied = scores.where((s) => s.runs == leader.runs).length > 1;
    if (!tied || game.inning >= baseballLastInning) {
      return game._next(
        scores: scores,
        visitsPlayed: game.visitsPlayed + 1,
        winner: leader.player,
      );
    }
  }
  return game._next(
    scores: scores,
    activeIndex: game.nextIndex,
    inningIndex: game.inningIndex + (roundIsOver ? 1 : 0),
    visitsPlayed: game.visitsPlayed + 1,
  );
}
