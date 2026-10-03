import 'dart.dart';
import 'game_config.dart';

/// Every dart that scores, from the board.
final List<Dart> _scoringDarts = [
  for (var sector = 20; sector >= 1; sector--) ...[
    Dart.treble(sector),
    Dart.single(sector),
    Dart.double(sector),
  ],
  Dart.outerBull,
  Dart.bull,
];

/// Doubles players prefer to finish on: they split into other doubles
/// after a single (D16 → D8 → D4, D20 → D10 → D5…). Lower is better.
const _doubleCost = {16: 0, 20: 0, 8: 1, 10: 1, 12: 1, 18: 1, 4: 2, 6: 2};

/// Trebles players practise setting up with. Lower is better.
const _trebleCost = {20: 2, 19: 2, 18: 3, 17: 3, 16: 3, 15: 4};

/// How much a player dislikes aiming at [dart] to set up a finish:
/// singles are the safest, then the usual trebles, the outer bull, and
/// doubles or the bull last.
int _setupCost(Dart dart) => switch (dart.multiplier) {
  1 when dart.sector == Dart.bullSector => 3,
  1 => 0,
  3 => _trebleCost[dart.sector] ?? 6,
  2 when dart.sector == Dart.bullSector => 6,
  _ => 8,
};

int _finishCost(Dart dart, OutRule rule) {
  if (rule == OutRule.straight) return _setupCost(dart);
  if (dart == Dart.bull) return 5;
  return _doubleCost[dart.sector] ?? 3;
}

/// Above this, no route is suggested, whatever the out rule (a 3-dart
/// finish on a double tops out at 170).
const maxCheckoutSuggestion = 170;

final Map<(int, int, OutRule), List<Dart>?> _routes = {};

/// The route a scorer would call to check out [remaining] with at most
/// [dartsLeft] darts under [rule]: fewest darts first, then the easiest
/// darts to hit. Null when it cannot be done.
List<Dart>? suggestCheckout(int remaining, int dartsLeft, OutRule rule) =>
    remaining < 1 || remaining > maxCheckoutSuggestion || dartsLeft < 1
    ? null
    : _routes.putIfAbsent((
        remaining,
        dartsLeft,
        rule,
      ), () => _search(remaining, dartsLeft, rule));

List<Dart>? _search(int remaining, int dartsLeft, OutRule rule) {
  final finishing = [
    for (final dart in _scoringDarts)
      if (rule.allowsFinishOn(dart)) dart,
  ];
  for (var darts = 1; darts <= dartsLeft; darts++) {
    List<Dart>? best;
    var bestCost = 0;
    void consider(List<Dart> setup, Dart finish) {
      final cost =
          setup.fold(0, (sum, d) => sum + _setupCost(d)) +
          _finishCost(finish, rule);
      if (best == null || cost < bestCost) {
        best = [...setup, finish];
        bestCost = cost;
      }
    }

    for (final finish in finishing) {
      final setupScore = remaining - finish.score;
      switch (darts) {
        case 1 when setupScore == 0:
          consider(const [], finish);
        case 2:
          for (final a in _scoringDarts) {
            if (a.score == setupScore) consider([a], finish);
          }
        case 3:
          // Higher-scoring setup dart first, as a scorer calls it.
          for (final (i, a) in _scoringDarts.indexed) {
            for (final b in _scoringDarts.skip(i)) {
              if (a.score + b.score != setupScore) continue;
              consider(a.score >= b.score ? [a, b] : [b, a], finish);
            }
          }
      }
    }
    if (best case final route?) {
      // Any dart may finish straight-out: call the biggest first.
      if (rule == OutRule.straight) {
        route.sort((a, b) => b.score.compareTo(a.score));
      }
      return List.unmodifiable(route);
    }
  }
  return null;
}
