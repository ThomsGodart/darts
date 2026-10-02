import 'package:darts_points_counter/soiree/soiree.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const doubleOut301 = X01Config(startScore: 301);

GameState gameOf(Soiree soiree) => soiree.state.game!;

/// Throws [darts] in order and fails the test on the first rejection.
void throwDarts(Soiree soiree, List<Dart> darts) {
  for (final dart in darts) {
    expect(soiree.throwDart(dart), isA<Accepted>(), reason: '$dart');
  }
}

/// A soirée where Alice has [remaining] left in a 1-player game.
Soiree aliceOn(int remaining, {OutRule outRule = OutRule.double}) => newSoiree()
  ..startGame([
    alice,
  ], config: X01Config(startScore: remaining, outRule: outRule));

void main() {
  test('dart scores', () {
    expect(Dart.single(20).score, 20);
    expect(Dart.double(20).score, 40);
    expect(Dart.treble(19).score, 57);
    expect(Dart.outerBull.score, 25);
    expect(Dart.bull.score, 50);
    expect(Dart.miss.score, 0);
  });

  test('a full visit of three darts passes the turn', () {
    final soiree = newSoiree()..startGame([alice, bob]);
    throwDarts(soiree, [Dart.treble(20), Dart.single(5), Dart.treble(20)]);

    final game = gameOf(soiree);
    expect(game.scoreOf(alice).remaining, 376);
    expect(game.scoreOf(alice).lastVisit!.points, 125);
    expect(game.activePlayer, bob);
    expect(game.dartsInVisit, isEmpty);
  });

  test('darts of the visit in progress are shown with a live remaining', () {
    final soiree = newSoiree()..startGame([alice, bob]);
    throwDarts(soiree, [Dart.treble(20), Dart.single(1)]);

    final game = gameOf(soiree);
    expect(game.dartsInVisit, [Dart.treble(20), Dart.single(1)]);
    expect(game.activeRemaining, 440);
    expect(game.scoreOf(alice).remaining, 501, reason: 'visit not complete');
    expect(game.activePlayer, alice);
  });

  group('busts end the visit at once', () {
    test('below zero', () {
      final soiree = aliceOn(50);
      throwDarts(soiree, [Dart.treble(20)]);

      final alices = gameOf(soiree).scoreOf(alice);
      expect(alices.remaining, 50);
      expect(alices.lastVisit!.isBust, isTrue);
      expect(alices.lastVisit!.darts, 1);
      expect(gameOf(soiree).dartsInVisit, isEmpty);
    });

    test('double-out: leaving 1', () {
      final soiree = aliceOn(41);
      throwDarts(soiree, [Dart.double(20)]);
      expect(gameOf(soiree).scoreOf(alice).lastVisit!.isBust, isTrue);
      expect(gameOf(soiree).scoreOf(alice).remaining, 41);
    });

    test('double-out: reaching 0 on a single is a bust', () {
      final soiree = aliceOn(40);
      throwDarts(soiree, [Dart.single(20), Dart.single(20)]);

      final alices = gameOf(soiree).scoreOf(alice);
      expect(alices.lastVisit!.isBust, isTrue);
      expect(alices.lastVisit!.darts, 2);
      expect(alices.remaining, 40);
      expect(gameOf(soiree).isFinished, isFalse);
    });

    test('double-out: reaching 0 on a treble is a bust', () {
      final soiree = aliceOn(60);
      throwDarts(soiree, [Dart.treble(20)]);
      expect(gameOf(soiree).scoreOf(alice).lastVisit!.isBust, isTrue);
    });
  });

  group('checkouts', () {
    test('double-out: finishing on a double wins', () {
      final soiree = aliceOn(100);
      throwDarts(soiree, [Dart.treble(20), Dart.double(20)]);

      final game = gameOf(soiree);
      expect(game.winner, alice);
      expect(game.scoreOf(alice).lastVisit!.darts, 2);
    });

    test('double-out: the bull counts as a double', () {
      final soiree = aliceOn(50);
      throwDarts(soiree, [Dart.bull]);
      expect(gameOf(soiree).winner, alice);
    });

    test('straight-out: finishing on a single wins', () {
      final soiree = aliceOn(20, outRule: OutRule.straight);
      throwDarts(soiree, [Dart.single(20)]);
      expect(gameOf(soiree).winner, alice);
    });

    test('no darts can be thrown once the game is won', () {
      final soiree = aliceOn(50);
      throwDarts(soiree, [Dart.bull]);
      expect(soiree.throwDart(Dart.single(1)), isA<Rejected>());
    });
  });

  test('totals and darts mix in one game; busts count real darts', () {
    final soiree = newSoiree()..startGame([alice, bob], config: doubleOut301);
    play(soiree, [180, 0]);
    // Alice on 121: T20 T20 leaves 1, a bust after two darts.
    throwDarts(soiree, [Dart.treble(20), Dart.treble(20)]);
    play(soiree, [0]);
    // Then 121 = T20 T11 D14 dart by dart.
    throwDarts(soiree, [Dart.treble(20), Dart.treble(11), Dart.double(14)]);

    // 180 + 0 + 121 points over 3 + 2 + 3 darts.
    final alices = gameOf(soiree).scoreOf(alice);
    expect(alices.remaining, 0);
    expect(gameOf(soiree).winner, alice);
    expect(alices.threeDartAverage, 301 / 8 * 3);
  });

  test('undo takes back one dart at a time', () {
    final soiree = newSoiree()..startGame([alice, bob]);
    throwDarts(soiree, [Dart.treble(20), Dart.single(5), Dart.treble(20)]);

    soiree.undo();
    var game = gameOf(soiree);
    expect(game.activePlayer, alice);
    expect(game.dartsInVisit, [Dart.treble(20), Dart.single(5)]);
    expect(game.activeRemaining, 436);

    soiree
      ..undo()
      ..undo();
    game = gameOf(soiree);
    expect(game.dartsInVisit, isEmpty);
    expect(game.activeRemaining, 501);
  });

  group('refused darts', () {
    test('a total cannot be entered once darts of the visit are thrown', () {
      final soiree = newSoiree()..startGame([alice, bob]);
      throwDarts(soiree, [Dart.single(20)]);
      expect(soiree.submitVisitTotal(60), isA<Rejected>());
    });

    test('no dart without a game', () {
      expect(newSoiree().throwDart(Dart.single(20)), isA<Rejected>());
    });
  });
}
