import 'package:darts_points_counter/soiree/soiree.dart';
import 'package:flutter_test/flutter_test.dart';

const alice = Player(id: 'alice', name: 'Alice');
const bob = Player(id: 'bob', name: 'Bob');

Soiree newSoiree() => Soiree(InMemoryJournal());

/// Submits [scores] in order and fails the test on the first rejection.
void play(Soiree soiree, List<int> scores) {
  for (final score in scores) {
    final result = soiree.submitVisitTotal(score);
    expect(result, isA<Accepted>(), reason: 'visit $score was rejected');
  }
}

/// Submits a visit that brings the remaining score to 0 in [darts] darts.
void checkOut(Soiree soiree, int score, {int darts = 3}) {
  final result = soiree.submitVisitTotal(score, dartsAtCheckout: darts);
  expect(result, isA<Accepted>(), reason: 'checkout $score was rejected');
}

/// What a player sees on the scoreboard; used to assert nothing changed.
List<Object?> scoreboardOf(Soiree soiree) {
  final game = soiree.state.game;
  if (game == null) return [];
  return [
    game.config,
    for (final s in game.scores)
      (s.player, s.remaining, s.lastVisit, s.threeDartAverage),
    game.activePlayer,
    game.dartsInVisit,
    game.winner,
  ];
}
