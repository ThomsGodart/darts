import 'package:darts_points_counter/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

PlayerStats statsOf(Player player, List<Session> sessions) =>
    playerStats([for (final session in sessions) session.state])
        .firstWhere((s) => s.player.id == player.id);

void main() {
  test('nobody played: no stats', () {
    expect(playerStats(const []), isEmpty);
  });

  test('X01: average, tons, first nine, best finish and best leg', () {
    final session = newSession()..startGame([alice, bob]);
    // Alice: 180, 140, 100, then 81 to finish 501 in 11 darts.
    play(session, [180, 26, 140, 26, 100, 26]);
    checkOut(session, 81, darts: 2);

    final stats = statsOf(alice, [session]);
    expect(stats.gamesPlayed, 1);
    expect(stats.gamesWon, 1);
    expect(stats.x01Average, closeTo(501 / 11 * 3, 0.001));
    expect(stats.firstNineAverage, closeTo(140, 0.001));
    expect(stats.tons, 3);
    expect(stats.ton40s, 2);
    expect(stats.ton80s, 1);
    expect(stats.bestCheckout, 81);
    expect(stats.fewestDartsToWin, 11);

    final loser = statsOf(bob, [session]);
    expect(loser.gamesWon, 0);
    expect(loser.bestCheckout, isNull);
    expect(loser.fewestDartsToWin, isNull);
    expect(loser.x01Average, closeTo(26, 0.001));
  });

  test('a bust is no ton', () {
    final session = newSession()
      ..startGame([alice], config: const X01Config(startScore: 101));
    play(session, [100]); // leaves 1: bust in double-out
    expect(statsOf(alice, [session]).tons, 0);
  });

  test('stats add up over sessions; the best ones are kept', () {
    final first = newSession()
      ..startGame([alice], config: const X01Config(startScore: 101));
    checkOut(first, 101);
    final second = newSession()
      ..startGame([alice], config: const X01Config(startScore: 40));
    play(second, [0]);
    checkOut(second, 40, darts: 1);

    final stats = statsOf(alice, [first, second]);
    expect(stats.gamesPlayed, 2);
    expect(stats.gamesWon, 2);
    expect(stats.bestCheckout, 101);
    expect(stats.fewestDartsToWin, 3);
    expect(stats.x01Average, closeTo(141 / 7 * 3, 0.001));
  });

  test('cricket: games and marks per round', () {
    final session = newSession()
      ..startGame([alice, bob], config: const CricketConfig());
    for (var i = 0; i < 3; i++) {
      session.throwDart(const Dart.treble(20));
    }

    final stats = statsOf(alice, [session]);
    expect(stats.marksPerRound, closeTo(9, 0.001));
    expect(stats.x01Average, isNull);
    expect(stats.gamesPlayed, 0, reason: 'the game is not over');
  });

  test('every kind counts in games played and won', () {
    final session = newSession()
      ..startGame([alice, bob], config: const GolfConfig());
    for (var i = 0; i < 18; i++) {
      session.endVisit();
    }

    expect(statsOf(alice, [session]).gamesWon, 1);
    expect(statsOf(bob, [session]).gamesPlayed, 1);
    expect(statsOf(bob, [session]).gamesWon, 0);
  });

  test('a renamed player stays one player, under the latest name', () {
    final first = newSession()..startGame([alice], config: const GolfConfig());
    final second = newSession()
      ..startGame([
        const Player(id: 'alice', name: 'Alicia'),
      ], config: const GolfConfig());

    final all = playerStats([first.state, second.state]);
    expect(all, hasLength(1));
    expect(all.single.player.name, 'Alicia');
  });
}
