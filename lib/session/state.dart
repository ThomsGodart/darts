import 'checkout.dart';
import 'dart.dart';
import 'player.dart';
import 'game_config.dart';
import 'match.dart';
import 'x01_rules.dart';

/// [count] per round, null before the first round.
double? perRound(int count, int rounds) => rounds == 0 ? null : count / rounds;

/// Points per three darts; null before the first dart.
double? averagePerVisit(int points, int darts) =>
    darts == 0 ? null : points / darts * dartsPerVisit;

class SessionState {
  const SessionState({
    this.games = const [],
    this.isEnded = false,
    this.confirmsVisits = true,
  });

  /// Whether the current game holds a visit open after its last dart
  /// until it is ended (see [GameStarted.confirmsVisits]).
  final bool confirmsVisits;

  /// Every game of the session, in the order they were played.
  final List<Game> games;

  /// Whether the session was ended; nothing more can be played then.
  final bool isEnded;

  /// The current (latest) game, or null when none has been started.
  Game? get game => games.lastOrNull;

  /// Everyone who played, in the order they first did, under the name they
  /// had in their latest game.
  List<Player> get players {
    // A map keeps each key where it was first inserted; values update.
    final byId = <String, Player>{
      for (final game in games)
        for (final player in game.players) player.id: player,
    };
    return byId.values.toList();
  }

  /// Three-dart average of [player] over their X01 games of the session;
  /// null if they have not thrown in one yet.
  /// Matched by id: a player renamed between games stays one player.
  double? averageOf(Player player) {
    var points = 0;
    var darts = 0;
    for (final game in games.whereType<X01Game>()) {
      for (final score in game.scores) {
        if (score.player.id != player.id) continue;
        points += score.pointsScored;
        darts += score.dartsThrown;
      }
    }
    return averagePerVisit(points, darts);
  }

  /// MPR of [player] over their cricket games of the session; null if
  /// they have not thrown in one yet.
  double? marksPerRoundOf(Player player) {
    var marks = 0;
    var rounds = 0;
    for (final game in games.whereType<CricketGame>()) {
      for (final score in game.scores) {
        if (score.player.id != player.id) continue;
        marks += score.marksHit;
        rounds += game.roundsOf(score.player);
      }
    }
    return perRound(marks, rounds);
  }

  /// The match the current game is a leg of; null when it is played
  /// alone, or is not an X01 game.
  MatchScore? get match => matchOf(games);

  /// The players of the current match, in the order they first played in
  /// the session: the throwing order turns with every leg, a score line
  /// should not.
  List<Player> get matchPlayers {
    final ids = {
      for (final player in match?.players ?? const <Player>[]) player.id,
    };
    return [
      for (final player in players)
        if (ids.contains(player.id)) player,
    ];
  }

  SessionState addGame(Game game, {bool confirmsVisits = true}) => SessionState(
    games: List.unmodifiable([...games, game]),
    isEnded: isEnded,
    confirmsVisits: confirmsVisits,
  );

  SessionState replaceCurrentGame(Game game) => SessionState(
    games: List.unmodifiable([...games.take(games.length - 1), game]),
    isEnded: isEnded,
    confirmsVisits: confirmsVisits,
  );
}

/// One visit as it was played.
class Visit {
  const Visit({
    required this.score,
    required this.darts,
    required this.isBust,
    this.dartsAtDouble,
    this.thrown = const [],
  });

  /// The darts of the visit when it was entered dart by dart, misses
  /// never thrown left out; empty when it was entered as a total.
  final List<Dart> thrown;

  /// Total entered for the visit, even when it busted.
  final int score;
  final int darts;
  final bool isBust;

  /// How many of the darts were thrown at a finish, i.e. with a one-dart
  /// finish left; null when the visit was entered as a total and nobody
  /// said.
  final int? dartsAtDouble;

  /// Points that count towards the remaining score and the average.
  int get points => isBust ? 0 : score;

  @override
  bool operator ==(Object other) =>
      other is Visit &&
      other.score == score &&
      other.darts == darts &&
      other.isBust == isBust &&
      other.dartsAtDouble == dartsAtDouble;

  @override
  int get hashCode => Object.hash(score, darts, isBust, dartsAtDouble);
}

class PlayerScore {
  const PlayerScore({
    required this.player,
    required this.remaining,
    this.visits = const [],
    this.pointsScored = 0,
    this.dartsThrown = 0,
    this.isIn = true,
  });

  final Player player;
  final int remaining;

  /// Whether the player's darts score: false in a double-in game until
  /// they hit a double.
  final bool isIn;

  /// Every visit the player completed in the game, in order.
  final List<Visit> visits;
  final int pointsScored;
  final int dartsThrown;

  /// The player's latest visit, null before their first.
  Visit? get lastVisit => visits.lastOrNull;

  int get visitsPlayed => visits.length;

  /// Points per three darts, null before the first dart.
  double? get threeDartAverage => averagePerVisit(pointsScored, dartsThrown);

  /// Visits [member] threw: all of them alone, or every Nth when [player]
  /// is a team whose members alternate.
  List<Visit> visitsOf(Player member) {
    if (!player.isTeam) {
      return member.id == player.id ? visits : const [];
    }
    final turn = player.members.indexWhere((m) => m.id == member.id);
    if (turn < 0) return const [];
    final turns = player.members.length;
    return [
      for (final (i, visit) in visits.indexed)
        if (i % turns == turn) visit,
    ];
  }

  /// [member]'s latest visit on this score, null before their first.
  Visit? lastVisitOf(Player member) => visitsOf(member).lastOrNull;

  /// Points per three darts for [member]'s own visits on this score.
  double? threeDartAverageOf(Player member) {
    final own = visitsOf(member);
    if (own.isEmpty) return null;
    final points = own.fold(0, (sum, visit) => sum + visit.points);
    final darts = own.fold(0, (sum, visit) => sum + visit.darts);
    return averagePerVisit(points, darts);
  }

  /// Darts [member] has thrown on this score.
  int dartsThrownBy(Player member) =>
      visitsOf(member).fold(0, (sum, visit) => sum + visit.darts);

  /// The score after [visit]; [isIn] says whether the player is in by
  /// the end of it.
  PlayerScore after(Visit visit, {required bool isIn}) => PlayerScore(
    player: player,
    isIn: isIn,
    remaining: remaining - visit.points,
    visits: List.unmodifiable([...visits, visit]),
    pointsScored: pointsScored + visit.points,
    dartsThrown: dartsThrown + visit.darts,
  );
}

/// What every game exposes, whatever is played.
sealed class Game {
  const Game();

  GameConfig get config;

  /// Players in throwing order.
  List<Player> get players;
  int get activeIndex;

  /// Darts already thrown in the active player's visit when it is entered
  /// dart by dart; empty between visits.
  List<Dart> get dartsInVisit;
  Player? get winner;

  /// Completed visits, all players together: changes on every turn.
  int get visitsPlayed;

  bool get isFinished => winner != null;

  /// Whether the visit in progress has had its last dart and waits to be
  /// ended.
  bool get visitIsOver => dartsInVisit.length >= dartsPerVisit;

  Player get activePlayer => players[activeIndex];

  /// Who is at the oche: the active player, or in a team whichever of its
  /// members' turn it is. A team's members alternate round after round.
  Player get thrower {
    final side = activePlayer;
    if (!side.isTeam) return side;
    final round = visitsPlayed ~/ players.length;
    return side.members[round % side.members.length];
  }

  /// Whoever throws after the active player, in throwing order.
  int get nextIndex => (activeIndex + 1) % players.length;

  /// Throwing order of a rematch: whoever started this game throws last.
  List<Player> get rematchOrder => [...players.skip(1), players.first];
}

/// An X01 game: each player counts down from the start score.
final class X01Game extends Game {
  const X01Game({
    required this.config,
    required this.scores,
    required this.activeIndex,
    this.dartsInVisit = const [],
    this.winner,
  });

  @override
  final X01Config config;

  /// One entry per player, in throwing order.
  final List<PlayerScore> scores;
  @override
  final int activeIndex;
  @override
  final List<Dart> dartsInVisit;
  @override
  final Player? winner;

  @override
  List<Player> get players => [for (final s in scores) s.player];

  PlayerScore get activeScore => scores[activeIndex];

  @override
  int get visitsPlayed => scores.fold(0, (sum, s) => sum + s.visitsPlayed);

  /// The active player's remaining score, counting darts already thrown.
  int get activeRemaining => activeScore.remaining - dartsInVisitScore;

  /// Whether the last dart thrown brought the remaining to 0 the way the
  /// out rule asks.
  bool get visitChecksOut =>
      dartsInVisit.isNotEmpty &&
      activeRemaining == 0 &&
      config.outRule.allowsFinishOn(dartsInVisit.last);

  /// Whether the darts thrown bust the visit.
  bool get visitBusts =>
      dartsInVisit.isNotEmpty &&
      !visitChecksOut &&
      (activeRemaining == 0 || config.outRule.bustsOn(activeRemaining));

  @override
  bool get visitIsOver => super.visitIsOver || visitBusts;

  /// The route to call for the active player to check out with the darts
  /// left in their visit; null when they cannot finish this visit.
  List<Dart>? get checkoutSuggestion =>
      isFinished || activeRemaining > maxCheckoutSuggestion
      ? null
      : suggestCheckout(
          activeRemaining,
          dartsPerVisit - dartsInVisit.length,
          config.outRule,
        );

  /// Points of the darts already thrown in the visit in progress: in a
  /// double-in game, none before the player's first double.
  int get dartsInVisitScore => countedScoreOf(dartsInVisit);

  /// What [darts] thrown by the active player in one visit count for.
  int countedScoreOf(List<Dart> darts) {
    var isIn = activeScore.isIn;
    var points = 0;
    for (final dart in darts) {
      isIn = isIn || dart.isDouble;
      if (isIn) points += dart.score;
    }
    return points;
  }

  /// How many of [darts], thrown by the active player in one visit, were
  /// thrown with a one-dart finish left.
  int dartsAtDoubleIn(List<Dart> darts) {
    final finishes = config.outRule.finishingDartScores;
    var count = 0;
    for (var i = 0; i < darts.length; i++) {
      final before =
          activeScore.remaining - countedScoreOf(darts.sublist(0, i));
      if (finishes.contains(before)) count++;
    }
    return count;
  }

  /// The counts of darts at a finish worth asking about for a visit of
  /// [score] entered as a total: empty when there is nothing to ask, a
  /// single value when it can only be that. [dartsAtCheckout] is how
  /// many darts a checkout took.
  ///
  /// Straight-out has no doubles to aim at: nothing is ever asked.
  List<int> doubleDartOptions(int score, {int? dartsAtCheckout}) {
    final outRule = config.outRule;
    if (outRule == OutRule.straight) return const [];
    final remaining = activeScore.remaining;
    final fewest = fewestDartsToFinish(remaining, outRule);
    if (fewest == null) return const [];
    // Darts spent getting to a finish were not thrown at one.
    final most = dartsPerVisit - (fewest - 1);
    final after = remaining - score;
    if (after == 0) {
      final thrown = dartsAtCheckout ?? dartsPerVisit;
      return [for (var n = 1; n <= thrown - (fewest - 1); n++) n];
    }
    final finishes = outRule.finishingDartScores;
    final nearAFinish =
        outRule.bustsOn(after) ||
        finishes.contains(after) ||
        finishes.contains(remaining);
    return nearAFinish ? [for (var n = 0; n <= most; n++) n] : const [];
  }

  /// Everyone but the active player, in the order they will throw next.
  List<PlayerScore> get waitingInTurnOrder => [
    for (var i = 1; i < scores.length; i++)
      scores[(activeIndex + i) % scores.length],
  ];

  /// Matched by id: a player renamed between games stays one player.
  PlayerScore scoreOf(Player player) =>
      scores.firstWhere((s) => s.player.id == player.id);

  /// Dart counts the active player may claim if a visit of [score] checks
  /// out; empty when it would not end the game validly.
  List<int> checkoutDartOptions(int score) {
    if (score != activeScore.remaining) return const [];
    final fewest = fewestDartsToFinish(score, config.outRule);
    if (fewest == null) return const [];
    return [for (var darts = fewest; darts <= dartsPerVisit; darts++) darts];
  }
}

/// One player's side of a cricket board.
class CricketScore {
  const CricketScore({
    required this.player,
    this.marks = const {},
    this.points = 0,
    this.visitsPlayed = 0,
    this.marksHit = 0,
    this.rounds = const [],
  });

  /// The darts of every visit the player completed, in order, misses
  /// never thrown left out.
  final List<List<Dart>> rounds;

  final Player player;

  /// Marks per cricket number, up to [marksToClose]; absent means none.
  final Map<int, int> marks;
  final int points;
  final int visitsPlayed;

  /// Every mark thrown on 15–20 and the bull: closing, scoring or dead.
  final int marksHit;

  int marksOn(int number) => marks[number] ?? 0;

  bool isClosed(int number) => marksOn(number) >= marksToClose;

  bool get hasClosedAll => cricketNumbers.every(isClosed);

  CricketScore copyWith({
    Map<int, int>? marks,
    int? points,
    int? visitsPlayed,
    int? marksHit,
    List<List<Dart>>? rounds,
  }) => CricketScore(
    player: player,
    marks: marks ?? this.marks,
    points: points ?? this.points,
    visitsPlayed: visitsPlayed ?? this.visitsPlayed,
    marksHit: marksHit ?? this.marksHit,
    rounds: rounds ?? this.rounds,
  );
}

/// A cricket game: close 15–20 and the bull, scoring on what others have
/// left open.
final class CricketGame extends Game {
  const CricketGame({
    required this.config,
    required this.scores,
    required this.activeIndex,
    this.dartsInVisit = const [],
    this.winner,
  });

  @override
  final CricketConfig config;

  /// One entry per player, in throwing order.
  final List<CricketScore> scores;
  @override
  final int activeIndex;
  @override
  final List<Dart> dartsInVisit;
  @override
  final Player? winner;

  @override
  List<Player> get players => [for (final s in scores) s.player];

  CricketScore get activeScore => scores[activeIndex];

  @override
  int get visitsPlayed => scores.fold(0, (sum, s) => sum + s.visitsPlayed);

  /// Matched by id: a player renamed between games stays one player.
  CricketScore scoreOf(Player player) =>
      scores.firstWhere((s) => s.player.id == player.id);

  /// Closed by every player: no one scores on it any more.
  bool isDead(int number) => scores.every((s) => s.isClosed(number));

  /// The round being played, counting from 1; once the game is won, how
  /// many it took its winner.
  int get round => activeScore.visitsPlayed + (isFinished ? 0 : 1);

  /// Rounds [player] has played, the visit in progress included.
  int roundsOf(Player player) {
    final score = scoreOf(player);
    final inProgress =
        score.player.id == activePlayer.id && dartsInVisit.isNotEmpty;
    return score.visitsPlayed + (inProgress ? 1 : 0);
  }

  /// MPR: marks per round, null before [player]'s first dart.
  double? marksPerRound(Player player) =>
      perRound(scoreOf(player).marksHit, roundsOf(player));
}

/// One player's side of a Shanghai game.
class ShanghaiScore {
  const ShanghaiScore({required this.player, this.points = 0});

  final Player player;
  final int points;

  ShanghaiScore copyWith({int? points}) =>
      ShanghaiScore(player: player, points: points ?? this.points);
}

/// A Shanghai game: score on a fixed number sequence; optional instant win
/// on S+D+T of the number in one visit.
final class ShanghaiGame extends Game {
  const ShanghaiGame({
    required this.config,
    required this.scores,
    required this.activeIndex,
    this.numberIndex = 0,
    this.visitsPlayed = 0,
    this.dartsInVisit = const [],
    this.winner,
  });

  @override
  final ShanghaiConfig config;

  /// One entry per player, in throwing order.
  final List<ShanghaiScore> scores;
  @override
  final int activeIndex;

  /// Index into [ShanghaiConfig.length.numbers].
  final int numberIndex;
  @override
  final int visitsPlayed;
  @override
  final List<Dart> dartsInVisit;
  @override
  final Player? winner;

  @override
  List<Player> get players => [for (final s in scores) s.player];

  /// Number everyone is throwing at.
  int get currentNumber => config.length.numbers[numberIndex];

  ShanghaiScore get activeScore => scores[activeIndex];

  int scoreOf(Player player) =>
      scores.firstWhere((s) => s.player.id == player.id).points;
}

/// Where Killer sits in its life cycle.
enum KillerPhase { assigning, playing, finished }

/// One player's side of a Killer game.
class KillerScore {
  const KillerScore({
    required this.player,
    this.number,
    this.lives,
    this.killerProgress = 0,
    this.isKiller = false,
  });

  final Player player;

  /// Claimed sector 1–20; null until assigned.
  final int? number;
  final int? lives;
  final int killerProgress;
  final bool isKiller;

  bool get isOut => lives != null && lives! <= 0;

  bool get hasNumber => number != null;

  KillerScore copyWith({
    int? number,
    int? lives,
    int? killerProgress,
    bool? isKiller,
  }) => KillerScore(
    player: player,
    number: number ?? this.number,
    lives: lives ?? this.lives,
    killerProgress: killerProgress ?? this.killerProgress,
    isKiller: isKiller ?? this.isKiller,
  );
}

/// A Killer game: claim a number, become Killer on its double, remove lives.
final class KillerGame extends Game {
  const KillerGame({
    required this.config,
    required this.scores,
    required this.activeIndex,
    this.phase = KillerPhase.assigning,
    this.visitsPlayed = 0,
    this.dartsInVisit = const [],
    this.winner,
  });

  @override
  final KillerConfig config;

  /// One entry per player, in throwing order.
  final List<KillerScore> scores;
  @override
  final int activeIndex;
  final KillerPhase phase;
  @override
  final int visitsPlayed;
  @override
  final List<Dart> dartsInVisit;
  @override
  final Player? winner;

  @override
  List<Player> get players => [for (final s in scores) s.player];

  @override
  bool get isFinished => phase == KillerPhase.finished || winner != null;

  KillerScore get activeScore => scores[activeIndex];

  KillerScore scoreOf(Player player) =>
      scores.firstWhere((s) => s.player.id == player.id);

  /// Numbers already claimed.
  Set<int> get takenNumbers => {
    for (final s in scores)
      if (s.number != null) s.number!,
  };

  /// Players still in (lives > 0), once playing has started.
  List<KillerScore> get alive => [
    for (final s in scores)
      if (!s.isOut) s,
  ];
}

/// One player's side of a Halve-It game.
class HalveItScore {
  const HalveItScore({
    required this.player,
    required this.points,
    this.wasHalved = false,
  });

  final Player player;
  final int points;

  /// Whether the player's latest visit missed the target and halved them.
  final bool wasHalved;
}

/// A Halve-It game: score on each target in turn; a visit without a hit
/// halves the score. The highest score after the last target wins.
final class HalveItGame extends Game {
  const HalveItGame({
    required this.config,
    required this.scores,
    required this.activeIndex,
    this.targetIndex = 0,
    this.visitsPlayed = 0,
    this.dartsInVisit = const [],
    this.winner,
  });

  @override
  final HalveItConfig config;

  /// One entry per player, in throwing order.
  final List<HalveItScore> scores;
  @override
  final int activeIndex;

  /// Index into [halveItTargets].
  final int targetIndex;
  @override
  final int visitsPlayed;
  @override
  final List<Dart> dartsInVisit;
  @override
  final Player? winner;

  @override
  List<Player> get players => [for (final s in scores) s.player];

  /// What everyone is throwing at.
  HalveItTarget get currentTarget => halveItTargets[targetIndex];

  HalveItScore get activeScore => scores[activeIndex];

  /// Points of the darts already thrown in the visit in progress.
  int get dartsInVisitScore =>
      dartsInVisit.fold(0, (sum, d) => sum + currentTarget.scoreOf(d));

  /// The active player's score, counting darts already thrown.
  int get activeLivePoints => activeScore.points + dartsInVisitScore;

  /// Matched by id: a player renamed between games stays one player.
  HalveItScore scoreOf(Player player) =>
      scores.firstWhere((s) => s.player.id == player.id);
}

/// One player's card in a Golf game.
class GolfScore {
  const GolfScore({required this.player, this.holeStrokes = const []});

  final Player player;

  /// Strokes on each hole played so far, in order.
  final List<int> holeStrokes;

  int get strokes => holeStrokes.fold(0, (sum, s) => sum + s);
}

/// A Golf game: hole n is the number n; up to three darts, the last one
/// thrown counts. The fewest strokes after the last hole win.
final class GolfGame extends Game {
  const GolfGame({
    required this.config,
    required this.scores,
    required this.activeIndex,
    this.holeIndex = 0,
    this.visitsPlayed = 0,
    this.dartsInVisit = const [],
    this.winner,
  });

  @override
  final GolfConfig config;

  /// One entry per player, in throwing order.
  final List<GolfScore> scores;
  @override
  final int activeIndex;

  /// Holes already played by everyone.
  final int holeIndex;
  @override
  final int visitsPlayed;
  @override
  final List<Dart> dartsInVisit;
  @override
  final Player? winner;

  @override
  List<Player> get players => [for (final s in scores) s.player];

  /// The hole being played, which is also the number to hit.
  int get currentHole => holeIndex + 1;

  GolfScore get activeScore => scores[activeIndex];

  /// Strokes the active player would take by stopping now.
  int get strokesIfStopped =>
      golfStrokes(dartsInVisit.lastOrNull, hole: currentHole);

  /// Matched by id: a player renamed between games stays one player.
  GolfScore scoreOf(Player player) =>
      scores.firstWhere((s) => s.player.id == player.id);
}

/// One player's progress around the clock.
class AroundTheClockScore {
  const AroundTheClockScore({required this.player, this.hits = 0});

  final Player player;

  /// Targets already hit, in order from 1.
  final int hits;
}

/// An Around the Clock game: hit 1 to 20 in order, any ring counting;
/// the first to finish wins.
final class AroundTheClockGame extends Game {
  const AroundTheClockGame({
    required this.config,
    required this.scores,
    required this.activeIndex,
    this.visitsPlayed = 0,
    this.dartsInVisit = const [],
    this.winner,
  });

  @override
  final AroundTheClockConfig config;

  /// One entry per player, in throwing order.
  final List<AroundTheClockScore> scores;
  @override
  final int activeIndex;
  @override
  final int visitsPlayed;
  @override
  final List<Dart> dartsInVisit;
  @override
  final Player? winner;

  @override
  List<Player> get players => [for (final s in scores) s.player];

  AroundTheClockScore get activeScore => scores[activeIndex];

  /// The number [score] must hit next: the bull once past 20.
  int targetOf(AroundTheClockScore score) =>
      score.hits < lastSector ? score.hits + 1 : Dart.bullSector;

  /// The number the active player must hit next.
  int get activeTarget => targetOf(activeScore);

  /// Matched by id: a player renamed between games stays one player.
  AroundTheClockScore scoreOf(Player player) =>
      scores.firstWhere((s) => s.player.id == player.id);
}

/// One player's side of a Bob's 27 game.
class Bobs27Score {
  const Bobs27Score({required this.player, required this.points});

  final Player player;
  final int points;

  /// Down to zero or less: the player throws no more.
  bool get isOut => points <= 0;
}

/// A Bob's 27 game: three darts at each double in turn, then the bull.
/// Hits add the target's value, a visit without one costs it; the highest
/// score wins.
final class Bobs27Game extends Game {
  const Bobs27Game({
    required this.config,
    required this.scores,
    required this.activeIndex,
    this.targetIndex = 0,
    this.visitsPlayed = 0,
    this.dartsInVisit = const [],
    this.winner,
  });

  @override
  final Bobs27Config config;

  /// One entry per player, in throwing order.
  final List<Bobs27Score> scores;
  @override
  final int activeIndex;

  /// Index into [bobs27Targets].
  final int targetIndex;
  @override
  final int visitsPlayed;
  @override
  final List<Dart> dartsInVisit;
  @override
  final Player? winner;

  @override
  List<Player> get players => [for (final s in scores) s.player];

  /// The double (or the bull) everyone is throwing at.
  Dart get currentTarget => bobs27Targets[targetIndex];

  Bobs27Score get activeScore => scores[activeIndex];

  /// Matched by id: a player renamed between games stays one player.
  Bobs27Score scoreOf(Player player) =>
      scores.firstWhere((s) => s.player.id == player.id);
}

/// One player's total in a Count-Up game.
class CountUpScore {
  const CountUpScore({required this.player, this.points = 0});

  final Player player;
  final int points;
}

/// A Count-Up game: every dart scores what it is worth; the highest total
/// after the last round wins.
final class CountUpGame extends Game {
  const CountUpGame({
    required this.config,
    required this.scores,
    required this.activeIndex,
    this.roundIndex = 0,
    this.visitsPlayed = 0,
    this.dartsInVisit = const [],
    this.winner,
  });

  @override
  final CountUpConfig config;

  /// One entry per player, in throwing order.
  final List<CountUpScore> scores;
  @override
  final int activeIndex;

  /// Rounds already thrown by everyone.
  final int roundIndex;
  @override
  final int visitsPlayed;
  @override
  final List<Dart> dartsInVisit;
  @override
  final Player? winner;

  @override
  List<Player> get players => [for (final s in scores) s.player];

  /// The round being thrown, from 1.
  int get round => roundIndex + 1;

  CountUpScore get activeScore => scores[activeIndex];

  /// The active player's total, counting darts already thrown.
  int get activeLivePoints =>
      activeScore.points + dartsInVisit.fold(0, (sum, d) => sum + d.score);

  /// Matched by id: a player renamed between games stays one player.
  CountUpScore scoreOf(Player player) =>
      scores.firstWhere((s) => s.player.id == player.id);
}

/// One player's runs in a Baseball game.
class BaseballScore {
  const BaseballScore({required this.player, this.runs = 0});

  final Player player;
  final int runs;
}

/// A Baseball game: inning n is thrown at the number n, a single scoring
/// 1 run, a double 2, a treble 3. The most runs after nine innings win;
/// a tie for the lead plays extra innings.
final class BaseballGame extends Game {
  const BaseballGame({
    required this.config,
    required this.scores,
    required this.activeIndex,
    this.inningIndex = 0,
    this.visitsPlayed = 0,
    this.dartsInVisit = const [],
    this.winner,
  });

  @override
  final BaseballConfig config;

  /// One entry per player, in throwing order.
  final List<BaseballScore> scores;
  @override
  final int activeIndex;

  /// Innings already played by everyone.
  final int inningIndex;
  @override
  final int visitsPlayed;
  @override
  final List<Dart> dartsInVisit;
  @override
  final Player? winner;

  @override
  List<Player> get players => [for (final s in scores) s.player];

  /// The inning being played, which is also the number to hit.
  int get inning => inningIndex + 1;

  BaseballScore get activeScore => scores[activeIndex];

  /// Runs [dart] scores in this inning.
  int runsOf(Dart dart) => dart.sector == inning ? dart.multiplier : 0;

  /// Matched by id: a player renamed between games stays one player.
  BaseballScore scoreOf(Player player) =>
      scores.firstWhere((s) => s.player.id == player.id);
}
