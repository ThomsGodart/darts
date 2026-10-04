import 'dart.dart';
import 'player.dart';

/// The highest number on the board.
const lastSector = 20;

/// Most players a game can have.
const maxPlayers = 8;

/// Darts thrown in a full visit.
const dartsPerVisit = 3;

/// Every score a single dart can make: singles, doubles, trebles, 25, bull.
final Set<int> singleDartScores = {
  for (var n = 1; n <= 20; n++) ...[n, 2 * n, 3 * n],
  25,
  50,
};

final Set<int> _doubles = {for (var n = 1; n <= 20; n++) 2 * n, 50};

final Set<int> _doublesAndTrebles = {
  ..._doubles,
  for (var n = 1; n <= 20; n++) 3 * n,
};

/// How a player is allowed to finish a leg.
enum OutRule {
  /// Any dart that brings the remaining score to exactly 0 wins.
  straight,

  /// The finishing dart must be a double (the bull counts as one).
  double,

  /// The finishing dart must be a double or a treble.
  master;

  /// Scores the finishing dart may make.
  Set<int> get finishingDartScores => switch (this) {
    straight => singleDartScores,
    double => _doubles,
    master => _doublesAndTrebles,
  };

  /// Whether [dart] may be the one that brings the remaining score to 0.
  bool allowsFinishOn(Dart dart) => switch (this) {
    straight => dart != Dart.miss,
    double => dart.isDouble,
    master => dart.isDouble || dart.multiplier == 3,
  };

  /// Whether a visit leaving [remaining] busts, whatever the last dart.
  bool bustsOn(int remaining) =>
      remaining < 0 || (remaining == 1 && !finishingDartScores.contains(1));
}

/// The games that can be played. Their names are stored with every game
/// started: never rename one.
enum GameKind {
  x01,
  cricket,
  shanghai,
  killer,
  halveIt,
  golf,
  aroundTheClock,
  bobs27,
  countUp,
  baseball,
}

/// Rules of a game, recorded with it so replays stay exact. Its type says
/// which game is played.
sealed class GameConfig {
  const GameConfig();

  GameKind get kind;

  /// Whether a game can be played with these rules.
  bool get isValid;

  /// Fewest players these rules can be played with.
  int get minPlayers => 1;
}

/// Rules of an X01 game: one leg, and the match it may be a leg of.
final class X01Config extends GameConfig {
  const X01Config({
    this.startScore = 501,
    this.outRule = OutRule.double,
    this.doubleIn = false,
    this.legsToWin = 1,
    this.setsToWin = 1,
  });

  /// Start scores the setup offers; any score above 1 can be played.
  static const offeredStartScores = [170, 301, 501, 701];

  /// Legs to win the setup offers: a single leg, or first to 2, 3 or 5.
  static const offeredLegsToWin = [1, 2, 3, 5];

  /// Sets to win the setup offers.
  static const offeredSetsToWin = [1, 2, 3];

  final int startScore;
  final OutRule outRule;

  /// Whether a player scores nothing until they hit a double.
  final bool doubleIn;

  /// Legs a player must win to take a set (the match, without sets).
  final int legsToWin;

  /// Sets a player must win to take the match.
  final int setsToWin;

  /// Whether legs are chained into a match, rather than played alone.
  bool get isMatch => legsToWin > 1 || setsToWin > 1;

  X01Config copyWith({
    int? startScore,
    OutRule? outRule,
    bool? doubleIn,
    int? legsToWin,
    int? setsToWin,
  }) => X01Config(
    startScore: startScore ?? this.startScore,
    outRule: outRule ?? this.outRule,
    doubleIn: doubleIn ?? this.doubleIn,
    legsToWin: legsToWin ?? this.legsToWin,
    setsToWin: setsToWin ?? this.setsToWin,
  );

  @override
  GameKind get kind => GameKind.x01;

  @override
  bool get isValid => startScore > 1 && legsToWin >= 1 && setsToWin >= 1;

  @override
  bool operator ==(Object other) =>
      other is X01Config &&
      other.startScore == startScore &&
      other.outRule == outRule &&
      other.doubleIn == doubleIn &&
      other.legsToWin == legsToWin &&
      other.setsToWin == setsToWin;

  @override
  int get hashCode =>
      Object.hash(startScore, outRule, doubleIn, legsToWin, setsToWin);
}

/// Numbers that count in cricket, as a board lists them; 25 is the bull.
const cricketNumbers = [20, 19, 18, 17, 16, 15, Dart.bullSector];

/// Marks a number needs to be closed.
const marksToClose = 3;

/// How the marks past a closed number are scored.
enum CricketVariant {
  /// They score for the thrower; the most points wins.
  standard,

  /// They score for every opponent still open; the fewest points wins.
  cutThroat;

  /// Whether extra marks score for the thrower, or against the others.
  bool get scoresForThrower => this == standard;

  /// Whether a player who closed everything on [points] wins against
  /// everyone's [allPoints] (theirs included): ties win.
  bool wins(int points, Iterable<int> allPoints) => switch (this) {
    standard => allPoints.every((p) => p <= points),
    cutThroat => allPoints.every((p) => p >= points),
  };
}

/// Where the darts of a cricket game are entered.
enum CricketInput {
  /// On the board itself: single, double and treble next to each number.
  board,

  /// On the dart keypad under the board.
  keypad,
}

/// Rules of a cricket game, and how the players chose to enter it.
final class CricketConfig extends GameConfig {
  const CricketConfig({
    this.variant = CricketVariant.standard,
    this.input = CricketInput.board,
  });

  final CricketVariant variant;
  final CricketInput input;

  @override
  GameKind get kind => GameKind.cricket;

  @override
  bool get isValid => true;

  @override
  bool operator ==(Object other) =>
      other is CricketConfig &&
      other.variant == variant &&
      other.input == input;

  @override
  int get hashCode => Object.hash(variant, input);
}

/// How long a Shanghai game runs.
enum ShanghaiLength {
  /// Numbers 1 through 7.
  oneToSeven,

  /// Numbers 14 through 20.
  fourteenToTwenty,

  /// Numbers 1 through 20.
  oneToTwenty;

  /// Numbers in order for this length.
  List<int> get numbers => switch (this) {
    oneToSeven => const [1, 2, 3, 4, 5, 6, 7],
    fourteenToTwenty => const [14, 15, 16, 17, 18, 19, 20],
    oneToTwenty => const [
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      19,
      20,
    ],
  };
}

/// Rules of a Shanghai game.
final class ShanghaiConfig extends GameConfig {
  const ShanghaiConfig({
    this.length = ShanghaiLength.oneToSeven,
    this.instantShanghai = true,
  });

  final ShanghaiLength length;

  /// Whether S+D+T of the number in one visit wins at once.
  final bool instantShanghai;

  @override
  GameKind get kind => GameKind.shanghai;

  @override
  bool get isValid => true;

  @override
  bool operator ==(Object other) =>
      other is ShanghaiConfig &&
      other.length == length &&
      other.instantShanghai == instantShanghai;

  @override
  int get hashCode => Object.hash(length, instantShanghai);
}

/// Fewest players for Killer.
const minKillerPlayers = 3;

/// Rules of a Killer game.
final class KillerConfig extends GameConfig {
  const KillerConfig({this.lives = 3, this.doublesToKiller = 1});

  static const livesOptions = [3, 5];
  static const doublesToKillerOptions = [1, 3];

  /// Lives each player starts with, one of [livesOptions].
  final int lives;

  /// Own doubles needed to become Killer, one of [doublesToKillerOptions].
  final int doublesToKiller;

  @override
  GameKind get kind => GameKind.killer;

  @override
  bool get isValid =>
      livesOptions.contains(lives) &&
      doublesToKillerOptions.contains(doublesToKiller);

  @override
  int get minPlayers => minKillerPlayers;

  @override
  bool operator ==(Object other) =>
      other is KillerConfig &&
      other.lives == lives &&
      other.doublesToKiller == doublesToKiller;

  @override
  int get hashCode => Object.hash(lives, doublesToKiller);
}

/// What a Halve-It round is thrown at: a number in any ring, or one ring
/// of it only.
class HalveItTarget {
  const HalveItTarget(this.sector, {this.multiplier});

  final int sector;

  /// The only ring that counts; null when the whole number does.
  final int? multiplier;

  /// What [dart] scores on this target; 0 when it lands elsewhere.
  int scoreOf(Dart dart) =>
      dart.sector == sector &&
          (multiplier == null || dart.multiplier == multiplier)
      ? dart.score
      : 0;

  /// "20", "D7", "T10", "Bull".
  String get label => switch ((sector, multiplier)) {
    (Dart.bullSector, _) => 'Bull',
    (_, 2) => 'D$sector',
    (_, 3) => 'T$sector',
    _ => '$sector',
  };
}

/// The rounds of a Halve-It game, in order.
const halveItTargets = [
  HalveItTarget(20),
  HalveItTarget(16),
  HalveItTarget(7, multiplier: 2),
  HalveItTarget(14),
  HalveItTarget(10, multiplier: 3),
  HalveItTarget(17),
  HalveItTarget(Dart.bullSector),
];

/// What every Halve-It player starts on, so that the first miss costs.
const halveItStartScore = 40;

/// Rules of a Halve-It game: there is nothing to choose.
final class HalveItConfig extends GameConfig {
  const HalveItConfig();

  @override
  GameKind get kind => GameKind.halveIt;

  @override
  bool get isValid => true;

  @override
  bool operator ==(Object other) => other is HalveItConfig;

  @override
  int get hashCode => (HalveItConfig).hashCode;
}

/// Strokes a missed hole costs in Golf.
const golfMissStrokes = 5;

/// Strokes the [last] dart of a visit costs on [hole]: a double 1, a
/// treble 2, a single 3; anything else, or no dart at all, a miss.
int golfStrokes(Dart? last, {required int hole}) {
  if (last == null || last.sector != hole) return golfMissStrokes;
  return switch (last.multiplier) {
    2 => 1,
    3 => 2,
    1 => 3,
    _ => golfMissStrokes,
  };
}

/// Rules of a Golf game.
final class GolfConfig extends GameConfig {
  const GolfConfig({this.holes = 9});

  static const holesOptions = [9, 18];

  /// Holes played, one of [holesOptions]: hole n is the number n.
  final int holes;

  @override
  GameKind get kind => GameKind.golf;

  @override
  bool get isValid => holesOptions.contains(holes);

  @override
  bool operator ==(Object other) => other is GolfConfig && other.holes == holes;

  @override
  int get hashCode => holes.hashCode;
}

/// Rules of an Around the Clock game.
final class AroundTheClockConfig extends GameConfig {
  const AroundTheClockConfig({this.finishOnBull = false});

  /// Whether the bull comes after 20, as the last target.
  final bool finishOnBull;

  /// Targets to hit to win: 1 to 20, then the bull if asked.
  int get targets => finishOnBull ? lastSector + 1 : lastSector;

  @override
  GameKind get kind => GameKind.aroundTheClock;

  @override
  bool get isValid => true;

  @override
  bool operator ==(Object other) =>
      other is AroundTheClockConfig && other.finishOnBull == finishOnBull;

  @override
  int get hashCode => finishOnBull.hashCode;
}

/// What every Bob's 27 player starts on.
const bobs27StartScore = 27;

/// The targets of Bob's 27, in order: double 1 to double 20, then the bull.
final List<Dart> bobs27Targets = List.unmodifiable([
  for (var n = 1; n <= 20; n++) Dart.double(n),
  Dart.bull,
]);

/// Rules of a Bob's 27 game: there is nothing to choose.
final class Bobs27Config extends GameConfig {
  const Bobs27Config();

  @override
  GameKind get kind => GameKind.bobs27;

  @override
  bool get isValid => true;

  @override
  bool operator ==(Object other) => other is Bobs27Config;

  @override
  int get hashCode => (Bobs27Config).hashCode;
}

/// Rules of a Count-Up game.
final class CountUpConfig extends GameConfig {
  const CountUpConfig({this.rounds = 8});

  static const roundsOptions = [8, 10];

  /// Visits each player throws, one of [roundsOptions].
  final int rounds;

  @override
  GameKind get kind => GameKind.countUp;

  @override
  bool get isValid => roundsOptions.contains(rounds);

  @override
  bool operator ==(Object other) =>
      other is CountUpConfig && other.rounds == rounds;

  @override
  int get hashCode => rounds.hashCode;
}

/// Innings of a Baseball game before any extra one.
const baseballInnings = 9;

/// The last inning that can be played, extra ones included: the board
/// has no number past it.
const baseballLastInning = lastSector;

/// Rules of a Baseball game: there is nothing to choose.
final class BaseballConfig extends GameConfig {
  const BaseballConfig();

  @override
  GameKind get kind => GameKind.baseball;

  @override
  bool get isValid => true;

  @override
  bool operator ==(Object other) => other is BaseballConfig;

  @override
  int get hashCode => (BaseballConfig).hashCode;
}

/// The rules a game of [kind] is offered with.
GameConfig defaultConfigOf(GameKind kind) => switch (kind) {
  GameKind.x01 => const X01Config(),
  GameKind.cricket => const CricketConfig(),
  GameKind.shanghai => const ShanghaiConfig(),
  GameKind.killer => const KillerConfig(),
  GameKind.halveIt => const HalveItConfig(),
  GameKind.golf => const GolfConfig(),
  GameKind.aroundTheClock => const AroundTheClockConfig(),
  GameKind.bobs27 => const Bobs27Config(),
  GameKind.countUp => const CountUpConfig(),
  GameKind.baseball => const BaseballConfig(),
};

/// What a game starts from: who plays, in throwing order, and the rules.
typedef GameSetup = ({List<Player> players, GameConfig config});
