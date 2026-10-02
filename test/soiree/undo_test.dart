import 'package:darts_points_counter/soiree/soiree.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const doubleOut301 = X01Config(startScore: 301);

GameState gameOf(Soiree soiree) => soiree.state.game!;

void main() {
  test('undo cancels the last visit and gives the turn back', () {
    final soiree = newSoiree()..startGame([alice, bob]);
    play(soiree, [60]);

    expect(soiree.undo(), isA<Accepted>());

    final game = gameOf(soiree);
    expect(game.scoreOf(alice).remaining, 501);
    expect(game.scoreOf(alice).lastVisit, isNull);
    expect(game.scoreOf(alice).threeDartAverage, isNull);
    expect(game.activePlayer, alice);
  });

  test('undo chains across several players', () {
    final soiree = newSoiree()..startGame([alice, bob]);
    play(soiree, [60, 45, 100]);

    soiree
      ..undo()
      ..undo();

    final game = gameOf(soiree);
    expect(game.scoreOf(alice).remaining, 441);
    expect(game.scoreOf(alice).lastVisit!.points, 60);
    expect(game.scoreOf(bob).remaining, 501);
    expect(game.activePlayer, bob);
  });

  test('undo after the checkout reopens the game', () {
    final soiree = newSoiree()..startGame([alice, bob], config: doubleOut301);
    play(soiree, [180, 0]);
    checkOut(soiree, 121);
    expect(gameOf(soiree).isFinished, isTrue);

    expect(soiree.undo(), isA<Accepted>());

    final game = gameOf(soiree);
    expect(game.isFinished, isFalse);
    expect(game.winner, isNull);
    expect(game.activePlayer, alice);
    expect(game.scoreOf(alice).remaining, 121);
    expect(soiree.submitVisitTotal(60), isA<Accepted>());
  });

  test('undo restores a bust as if it never happened', () {
    final soiree = newSoiree()..startGame([alice, bob], config: doubleOut301);
    play(soiree, [180, 0, 140]);

    soiree.undo();

    expect(gameOf(soiree).scoreOf(alice).lastVisit!.isBust, isFalse);
    expect(gameOf(soiree).activePlayer, alice);
  });

  group('nothing to undo', () {
    test('before any game', () {
      final soiree = newSoiree();
      expect(soiree.canUndo, isFalse);
      expect(soiree.undo(), isA<Rejected>());
    });

    test('at the start of a game: the game itself is not undone', () {
      final soiree = newSoiree()..startGame([alice, bob]);
      expect(soiree.canUndo, isFalse);
      expect(soiree.undo(), isA<Rejected>());
      expect(soiree.state.game, isNotNull);
    });

    test('after undoing every visit', () {
      final soiree = newSoiree()..startGame([alice, bob]);
      play(soiree, [60]);
      expect(soiree.canUndo, isTrue);

      soiree.undo();
      expect(soiree.canUndo, isFalse);
      expect(soiree.undo(), isA<Rejected>());
    });
  });
}
