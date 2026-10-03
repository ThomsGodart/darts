import 'x01_config.dart';

/// Totals reachable with up to three darts (a miss scores 0).
final Set<int> _possibleVisitTotals = {
  for (final a in {0, ...singleDartScores})
    for (final b in {0, ...singleDartScores})
      for (final c in {0, ...singleDartScores}) a + b + c,
};

bool isPossibleVisitTotal(int total) => _possibleVisitTotals.contains(total);

/// Fewest darts that can finish [remaining] under [rule], or null when it
/// cannot be finished in one visit (e.g. 169 double-out, anything > 180).
int? fewestDartsToFinish(int remaining, OutRule rule) {
  final finishing = rule.finishingDartScores;
  if (finishing.contains(remaining)) return 1;
  for (final a in singleDartScores) {
    if (finishing.contains(remaining - a)) return 2;
  }
  for (final a in singleDartScores) {
    for (final b in singleDartScores) {
      if (finishing.contains(remaining - a - b)) return 3;
    }
  }
  return null;
}
