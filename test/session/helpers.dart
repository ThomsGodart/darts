import 'package:darts_points_counter/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

const alice = Player(id: 'alice', name: 'Alice');
const bob = Player(id: 'bob', name: 'Bob');

Session newSession() => Session(InMemoryJournal());

/// Submits [scores] in order and fails the test on the first rejection.
void play(Session session, List<int> scores) {
  for (final score in scores) {
    final result = session.submitVisitTotal(score);
    expect(result, isA<Accepted>(), reason: 'visit $score was rejected');
  }
}

/// Submits a visit that brings the remaining score to 0 in [darts] darts.
void checkOut(Session session, int score, {int darts = 3}) {
  final result = session.submitVisitTotal(score, dartsAtCheckout: darts);
  expect(result, isA<Accepted>(), reason: 'checkout $score was rejected');
}

/// What a player sees on the scoreboard; used to assert nothing changed.
List<Object?> scoreboardOf(Session session) {
  final game = session.state.game;
  if (game == null) return [];
  return [
    game.config,
    ...switch (game) {
      X01Game(:final scores) => [
        for (final s in scores)
          (s.player, s.remaining, s.lastVisit, s.threeDartAverage),
      ],
      CricketGame(:final scores) => [
        for (final s in scores)
          (s.player, {...s.marks}.toString(), s.points, s.visitsPlayed),
      ],
    },
    game.activePlayer,
    game.dartsInVisit,
    game.winner,
  ];
}

/// The current game as an X01 game, for tests that only play X01.
extension X01Access on SessionState {
  X01Game? get x01 => game as X01Game?;
}
