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

  /// Whether a visit leaving [remaining] busts.
  bool bustsOn(int remaining) =>
      remaining < 0 || (remaining == 1 && !finishingDartScores.contains(1));
}

/// Rules of an X01 game, recorded with each game so replays stay exact.
class X01Config {
  const X01Config({this.startScore = 501, this.outRule = OutRule.double});

  final int startScore;
  final OutRule outRule;

  bool get isValid => startScore > 1;

  @override
  bool operator ==(Object other) =>
      other is X01Config &&
      other.startScore == startScore &&
      other.outRule == outRule;

  @override
  int get hashCode => Object.hash(startScore, outRule);
}
