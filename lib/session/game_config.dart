import 'dart.dart';
import 'player.dart';

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

/// How a player is allowed to finish a leg.
enum OutRule {
  /// Any dart that brings the remaining score to exactly 0 wins.
  straight,

  /// The finishing dart must be a double (the bull counts as one).
  double;

  /// Scores the finishing dart may make.
  Set<int> get finishingDartScores => switch (this) {
    straight => singleDartScores,
    double => _doubles,
  };

  /// Whether [dart] may be the one that brings the remaining score to 0.
  bool allowsFinishOn(Dart dart) => switch (this) {
    straight => dart != Dart.miss,
    double => dart.isDouble,
  };

  /// Whether a visit leaving [remaining] busts, whatever the last dart.
  bool bustsOn(int remaining) =>
      remaining < 0 || (remaining == 1 && !finishingDartScores.contains(1));
}

/// The games that can be played. Their names are stored with every game
/// started: never rename one.
enum GameKind { x01, cricket, shanghai, killer, halveIt, golf }

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

/// Rules of an X01 game.
final class X01Config extends GameConfig {
  const X01Config({this.startScore = 501, this.outRule = OutRule.double});

  /// Start scores the setup offers; any score above 1 can be played.
  static const offeredStartScores = [501, 301];

  final int startScore;
  final OutRule outRule;

  @override
  GameKind get kind => GameKind.x01;

  @override
  bool get isValid => startScore > 1;

  @override
  bool operator ==(Object other) =>
      other is X01Config &&
      other.startScore == startScore &&
      other.outRule == outRule;

  @override
  int get hashCode => Object.hash(startScore, outRule);
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

/// The rules a game of [kind] is offered with.
GameConfig defaultConfigOf(GameKind kind) => switch (kind) {
  GameKind.x01 => const X01Config(),
  GameKind.cricket => const CricketConfig(),
  GameKind.shanghai => const ShanghaiConfig(),
  GameKind.killer => const KillerConfig(),
  GameKind.halveIt => const HalveItConfig(),
  GameKind.golf => const GolfConfig(),
};

/// What a game starts from: who plays, in throwing order, and the rules.
typedef GameSetup = ({List<Player> players, GameConfig config});
