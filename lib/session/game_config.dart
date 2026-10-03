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

/// Rules of a game, recorded with it so replays stay exact. Its type says
/// which game is played.
sealed class GameConfig {
  const GameConfig();

  /// Whether a game can be played with these rules.
  bool get isValid;
}

/// Rules of an X01 game.
final class X01Config extends GameConfig {
  const X01Config({this.startScore = 501, this.outRule = OutRule.double});

  final int startScore;
  final OutRule outRule;

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
  bool get isValid => true;

  @override
  bool operator ==(Object other) =>
      other is ShanghaiConfig &&
      other.length == length &&
      other.instantShanghai == instantShanghai;

  @override
  int get hashCode => Object.hash(length, instantShanghai);
}

/// Fewest / most players for Killer.
const minKillerPlayers = 3;

/// Rules of a Killer game.
final class KillerConfig extends GameConfig {
  const KillerConfig({this.lives = 3, this.doublesToKiller = 1});

  /// Lives each player starts with: 3 or 5.
  final int lives;

  /// Own doubles needed to become Killer: 1 or 3.
  final int doublesToKiller;

  @override
  bool get isValid =>
      (lives == 3 || lives == 5) &&
      (doublesToKiller == 1 || doublesToKiller == 3);

  @override
  bool operator ==(Object other) =>
      other is KillerConfig &&
      other.lives == lives &&
      other.doublesToKiller == doublesToKiller;

  @override
  int get hashCode => Object.hash(lives, doublesToKiller);
}

/// What a game starts from: who plays, in throwing order, and the rules.
typedef GameSetup = ({List<Player> players, GameConfig config});
