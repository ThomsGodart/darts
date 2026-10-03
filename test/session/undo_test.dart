import 'package:darts_points_counter/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const doubleOut301 = X01Config(startScore: 301);

X01Game gameOf(Session session) => session.state.x01!;

void main() {
  test('undo cancels the last visit and gives the turn back', () {
    final session = newSession()..startGame([alice, bob]);
    play(session, [60]);

    expect(session.undo(), isA<Accepted>());

    final game = gameOf(session);
    expect(game.scoreOf(alice).remaining, 501);
    expect(game.scoreOf(alice).lastVisit, isNull);
    expect(game.scoreOf(alice).threeDartAverage, isNull);
    expect(game.activePlayer, alice);
  });

  test('undo chains across several players', () {
    final session = newSession()..startGame([alice, bob]);
    play(session, [60, 45, 100]);

    session
      ..undo()
      ..undo();

    final game = gameOf(session);
    expect(game.scoreOf(alice).remaining, 441);
    expect(game.scoreOf(alice).lastVisit!.points, 60);
    expect(game.scoreOf(bob).remaining, 501);
    expect(game.activePlayer, bob);
  });

  test('undo after the checkout reopens the game', () {
    final session = newSession()..startGame([alice, bob], config: doubleOut301);
    play(session, [180, 0]);
    checkOut(session, 121);
    expect(gameOf(session).isFinished, isTrue);

    expect(session.undo(), isA<Accepted>());

    final game = gameOf(session);
    expect(game.isFinished, isFalse);
    expect(game.winner, isNull);
    expect(game.activePlayer, alice);
    expect(game.scoreOf(alice).remaining, 121);
    expect(session.submitVisitTotal(60), isA<Accepted>());
  });

  test('undo restores a bust as if it never happened', () {
    final session = newSession()..startGame([alice, bob], config: doubleOut301);
    play(session, [180, 0, 140]);

    session.undo();

    expect(gameOf(session).scoreOf(alice).lastVisit!.isBust, isFalse);
    expect(gameOf(session).activePlayer, alice);
  });

  group('nothing to undo', () {
    test('before any game', () {
      final session = newSession();
      expect(session.canUndo, isFalse);
      expect(session.undo(), isA<Rejected>());
    });

    test('at the start of a game: the game itself is not undone', () {
      final session = newSession()..startGame([alice, bob]);
      expect(session.canUndo, isFalse);
      expect(session.undo(), isA<Rejected>());
      expect(session.state.game, isNotNull);
    });

    test('after undoing every visit', () {
      final session = newSession()..startGame([alice, bob]);
      play(session, [60]);
      expect(session.canUndo, isTrue);

      session.undo();
      expect(session.canUndo, isFalse);
      expect(session.undo(), isA<Rejected>());
    });
  });
}
