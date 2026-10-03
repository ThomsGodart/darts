import 'dart.dart';

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
}

/// Rules of a cricket game.
final class CricketConfig extends GameConfig {
  const CricketConfig({this.variant = CricketVariant.standard});

  final CricketVariant variant;

  @override
  bool get isValid => true;

  @override
  bool operator ==(Object other) =>
      other is CricketConfig && other.variant == variant;

  @override
  int get hashCode => variant.hashCode;
}
