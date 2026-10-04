import 'dart:math';

import 'state.dart';
import 'x01_rules.dart';

/// What a virtual opponent enters for a visit.
typedef BotVisit = ({int score, int? dartsAtCheckout});

/// A visit total around [average], as a player of that level throws when
/// only scoring matters: any total three darts can make, spread around
/// the average.
int botCountUpVisit(int average, Random random) {
  // Two uniforms make a bell around 0, in -1..1.
  final spread = random.nextDouble() + random.nextDouble() - 1;
  final deviation = max(18, average * 0.45);
  final score = (average + spread * deviation * 2.45).round().clamp(0, 180);
  return _possibleAtMost(score);
}

/// The visit the active player of [game], a virtual opponent, enters:
/// scores around its average, and takes a finish in reach with a chance
/// that grows with its level.
BotVisit botVisit(X01Game game, Random random) {
  final average = game.activePlayer.botAverage ?? 40;
  final remaining = game.activeScore.remaining;
  final outRule = game.config.outRule;

  final finishes = game.checkoutDartOptions(remaining);
  if (finishes.isNotEmpty) {
    // 40 → about 1 in 5 on a double; 80 → about 1 in 2. Big finishes are
    // rarer.
    final chance =
        ((average - 10) / 150).clamp(0.05, 0.6) * (remaining > 100 ? 0.35 : 1);
    if (random.nextDouble() < chance) {
      return (
        score: remaining,
        dartsAtCheckout: finishes[random.nextInt(finishes.length)],
      );
    }
    // On a double and missing it: nothing, or half of it.
    if (remaining <= 60) {
      final half = remaining ~/ 2;
      final leavesAFinish =
          remaining.isEven && half > 1 && !outRule.bustsOn(half);
      return (
        score: leavesAFinish && random.nextBool() ? half : 0,
        dartsAtCheckout: null,
      );
    }
  }

  // Scoring: never past what leaves something to finish on.
  var score = min(botCountUpVisit(average, random), remaining - 2);
  while (score > 0 &&
      (!isPossibleVisitTotal(score) || outRule.bustsOn(remaining - score))) {
    score--;
  }
  return (score: max(score, 0), dartsAtCheckout: null);
}

/// The highest total three darts can make that is not above [score].
int _possibleAtMost(int score) {
  var total = score;
  while (!isPossibleVisitTotal(total)) {
    total--;
  }
  return total;
}
