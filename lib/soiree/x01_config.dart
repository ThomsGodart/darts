/// How a player is allowed to finish a leg.
enum OutRule {
  /// Any dart that brings the remaining score to exactly 0 wins.
  straight,
}

/// Rules of an X01 game, recorded with each game so replays stay exact.
class X01Config {
  const X01Config({this.startScore = 501, this.outRule = OutRule.straight});

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
