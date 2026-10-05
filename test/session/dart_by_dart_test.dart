import 'package:darts_points_counter/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const doubleOut301 = X01Config(startScore: 301);

X01Game gameOf(Session session) => session.state.x01!;

/// Throws [darts] in order and fails the test on the first rejection.
void throwDarts(Session session, List<Dart> darts) {
  for (final dart in darts) {
    expect(session.throwDart(dart), isA<Accepted>(), reason: '$dart');
  }
}

/// A session where Alice has [remaining] left in a 1-player game.
Session aliceOn(int remaining, {OutRule outRule = OutRule.double}) =>
    newSession()..startGame([
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

  test('a full visit waits to be ended, then passes the turn', () {
    final session = newSession()..startGame([alice, bob]);
    throwDarts(session, [Dart.treble(20), Dart.single(5), Dart.treble(20)]);

    expect(gameOf(session).activePlayer, alice, reason: 'still to be read');
    expect(gameOf(session).dartsInVisit, hasLength(3));
    expect(gameOf(session).activeRemaining, 376);
    expect(session.throwDart(Dart.miss), isA<Rejected>());
    session.endVisit();

    final game = gameOf(session);
    expect(game.scoreOf(alice).remaining, 376);
    expect(game.scoreOf(alice).lastVisit!.points, 125);
    expect(game.activePlayer, bob);
    expect(game.dartsInVisit, isEmpty);
  });

  test('darts of the visit in progress are shown with a live remaining', () {
    final session = newSession()..startGame([alice, bob]);
    throwDarts(session, [Dart.treble(20), Dart.single(1)]);

    final game = gameOf(session);
    expect(game.dartsInVisit, [Dart.treble(20), Dart.single(1)]);
    expect(game.activeRemaining, 440);
    expect(game.scoreOf(alice).remaining, 501, reason: 'visit not complete');
    expect(game.activePlayer, alice);
  });

  group('busts stop the visit on their dart', () {
    test('below zero', () {
      final session = aliceOn(50);
      throwDarts(session, [Dart.treble(20)]);

      expect(gameOf(session).visitBusts, isTrue);
      expect(gameOf(session).dartsInVisit, [Dart.treble(20)]);
      expect(session.throwDart(Dart.miss), isA<Rejected>());
      session.endVisit();

      final alices = gameOf(session).scoreOf(alice);
      expect(alices.remaining, 50);
      expect(alices.lastVisit!.isBust, isTrue);
      expect(alices.lastVisit!.darts, 1);
      expect(gameOf(session).dartsInVisit, isEmpty);
    });

    test('double-out: leaving 1', () {
      final session = aliceOn(41);
      throwDarts(session, [Dart.double(20)]);
      session.endVisit();
      expect(gameOf(session).scoreOf(alice).lastVisit!.isBust, isTrue);
      expect(gameOf(session).scoreOf(alice).remaining, 41);
    });

    test('double-out: reaching 0 on a single is a bust', () {
      final session = aliceOn(40);
      throwDarts(session, [Dart.single(20), Dart.single(20)]);
      session.endVisit();

      final alices = gameOf(session).scoreOf(alice);
      expect(alices.lastVisit!.isBust, isTrue);
      expect(alices.lastVisit!.darts, 2);
      expect(alices.remaining, 40);
      expect(gameOf(session).isFinished, isFalse);
    });

    test('double-out: reaching 0 on a treble is a bust', () {
      final session = aliceOn(60);
      throwDarts(session, [Dart.treble(20)]);
      session.endVisit();
      expect(gameOf(session).scoreOf(alice).lastVisit!.isBust, isTrue);
    });
  });

  group('checkouts', () {
    test('double-out: finishing on a double wins', () {
      final session = aliceOn(100);
      throwDarts(session, [Dart.treble(20), Dart.double(20)]);

      final game = gameOf(session);
      expect(game.winner, alice);
      expect(game.scoreOf(alice).lastVisit!.darts, 2);
    });

    test('double-out: the bull counts as a double', () {
      final session = aliceOn(50);
      throwDarts(session, [Dart.bull]);
      expect(gameOf(session).winner, alice);
    });

    test('straight-out: finishing on a single wins', () {
      final session = aliceOn(20, outRule: OutRule.straight);
      throwDarts(session, [Dart.single(20)]);
      expect(gameOf(session).winner, alice);
    });

    test('no darts can be thrown once the game is won', () {
      final session = aliceOn(50);
      throwDarts(session, [Dart.bull]);
      expect(session.throwDart(Dart.single(1)), isA<Rejected>());
    });
  });

  test('totals and darts mix in one game; busts count real darts', () {
    final session = newSession()..startGame([alice, bob], config: doubleOut301);
    play(session, [180, 0]);
    // Alice on 121: T20 T20 leaves 1, a bust after two darts.
    throwDarts(session, [Dart.treble(20), Dart.treble(20)]);
    session.endVisit();
    play(session, [0]);
    // Then 121 = T20 T11 D14 dart by dart.
    throwDarts(session, [Dart.treble(20), Dart.treble(11), Dart.double(14)]);

    // 180 + 0 + 121 points over 3 + 2 + 3 darts.
    final alices = gameOf(session).scoreOf(alice);
    expect(alices.remaining, 0);
    expect(gameOf(session).winner, alice);
    expect(alices.threeDartAverage, 301 / 8 * 3);
  });

  test('undo takes back one dart at a time', () {
    final session = newSession()..startGame([alice, bob]);
    throwDarts(session, [Dart.treble(20), Dart.single(5), Dart.treble(20)]);

    session.undo();
    var game = gameOf(session);
    expect(game.activePlayer, alice);
    expect(game.dartsInVisit, [Dart.treble(20), Dart.single(5)]);
    expect(game.activeRemaining, 436);

    session
      ..undo()
      ..undo();
    game = gameOf(session);
    expect(game.dartsInVisit, isEmpty);
    expect(game.activeRemaining, 501);
  });

  group('refused darts', () {
    test('a total cannot be entered once darts of the visit are thrown', () {
      final session = newSession()..startGame([alice, bob]);
      throwDarts(session, [Dart.single(20)]);
      expect(session.submitVisitTotal(60), isA<Rejected>());
    });

    test('no dart without a game', () {
      expect(newSession().throwDart(Dart.single(20)), isA<Rejected>());
    });
  });
}
