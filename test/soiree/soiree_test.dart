import 'package:darts_points_counter/soiree/soiree.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  test('no game is running before one is started', () {
    expect(newSoiree().state.game, isNull);
  });

  test('a new 501 game: everyone on 501, first player to throw', () {
    final soiree = newSoiree();
    expect(soiree.startGame([alice, bob]), isA<Accepted>());

    final game = soiree.state.game!;
    expect(game.scores.map((s) => s.remaining), [501, 501]);
    expect(game.activePlayer, alice);
    expect(game.isFinished, isFalse);
    expect(game.scores.every((s) => s.lastVisit == null), isTrue);
  });

  test('a visit lowers the remaining score and passes the turn', () {
    final soiree = newSoiree()..startGame([alice, bob]);
    play(soiree, [60]);

    final game = soiree.state.game!;
    expect(game.scoreOf(alice).remaining, 441);
    expect(game.scoreOf(alice).lastVisit!.points, 60);
    expect(game.activePlayer, bob);
  });

  test('turns cycle back to the first player', () {
    final soiree = newSoiree()..startGame([alice, bob]);
    play(soiree, [60, 45]);

    final game = soiree.state.game!;
    expect(game.activePlayer, alice);
    expect(game.scoreOf(bob).remaining, 456);
  });

  test('301 starts everyone on 301', () {
    final soiree = newSoiree()
      ..startGame([alice, bob], config: const X01Config(startScore: 301));
    expect(soiree.state.game!.scores.map((s) => s.remaining), [301, 301]);
  });

  test('Alice and Bob, 501: Alice checks out exactly and wins', () {
    final soiree = newSoiree()..startGame([alice, bob]);
    play(soiree, [180, 60, 180, 60]);
    checkOut(soiree, 141);

    final game = soiree.state.game!;
    expect(game.scoreOf(alice).remaining, 0);
    expect(game.isFinished, isTrue);
    expect(game.winner, alice);
  });

  test('going below zero is a bust: nothing scored, turn passes', () {
    final soiree = newSoiree()
      ..startGame([alice, bob], config: const X01Config(startScore: 301));
    play(soiree, [180, 0, 140]);

    final game = soiree.state.game!;
    expect(game.scoreOf(alice).remaining, 121);
    expect(game.scoreOf(alice).lastVisit!.isBust, isTrue);
    expect(game.scoreOf(alice).lastVisit!.points, 0);
    expect(game.activePlayer, bob);
    expect(game.isFinished, isFalse);
  });

  group('rejections leave the state untouched', () {
    test('a visit without a game', () {
      final soiree = newSoiree();
      expect(soiree.submitVisitTotal(60), isA<Rejected>());
      expect(soiree.state.game, isNull);
    });

    test('a total outside 0..180', () {
      final soiree = newSoiree()..startGame([alice, bob]);
      final before = scoreboardOf(soiree);

      expect(soiree.submitVisitTotal(181), isA<Rejected>());
      expect(soiree.submitVisitTotal(-1), isA<Rejected>());
      expect(scoreboardOf(soiree), before);
    });

    test('a visit after the game is over', () {
      final soiree = newSoiree()
        ..startGame([alice, bob], config: const X01Config(startScore: 301));
      play(soiree, [180, 0]);
      checkOut(soiree, 121);
      final before = scoreboardOf(soiree);

      expect(soiree.submitVisitTotal(60), isA<Rejected>());
      expect(scoreboardOf(soiree), before);
    });

    test('a new game while one is in progress', () {
      final soiree = newSoiree()..startGame([alice, bob]);
      play(soiree, [60]);
      final before = scoreboardOf(soiree);

      expect(soiree.startGame([bob, alice]), isA<Rejected>());
      expect(scoreboardOf(soiree), before);
    });

    test('a start score that cannot be finished', () {
      final soiree = newSoiree();
      expect(
        soiree.startGame([alice], config: const X01Config(startScore: 0)),
        isA<Rejected>(),
      );
      expect(soiree.state.game, isNull);
    });

    test('a game without players', () {
      final soiree = newSoiree();
      expect(soiree.startGame([]), isA<Rejected>());
      expect(soiree.state.game, isNull);
    });
  });

  test('a new game can start once the previous one is over', () {
    final soiree = newSoiree()
      ..startGame([alice, bob], config: const X01Config(startScore: 301));
    play(soiree, [180, 0]);
    checkOut(soiree, 121);

    expect(soiree.startGame([bob, alice]), isA<Accepted>());
    expect(soiree.state.game!.activePlayer, bob);
    expect(soiree.state.game!.isFinished, isFalse);
  });
}
