import 'package:darts_points_counter/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  test('no game is running before one is started', () {
    expect(newSession().state.game, isNull);
  });

  test('a new 501 game: everyone on 501, first player to throw', () {
    final session = newSession();
    expect(session.startGame([alice, bob]), isA<Accepted>());

    final game = session.state.game!;
    expect(game.scores.map((s) => s.remaining), [501, 501]);
    expect(game.activePlayer, alice);
    expect(game.isFinished, isFalse);
    expect(game.scores.every((s) => s.lastVisit == null), isTrue);
  });

  test('a visit lowers the remaining score and passes the turn', () {
    final session = newSession()..startGame([alice, bob]);
    play(session, [60]);

    final game = session.state.game!;
    expect(game.scoreOf(alice).remaining, 441);
    expect(game.scoreOf(alice).lastVisit!.points, 60);
    expect(game.activePlayer, bob);
  });

  test('turns cycle back to the first player', () {
    final session = newSession()..startGame([alice, bob]);
    play(session, [60, 45]);

    final game = session.state.game!;
    expect(game.activePlayer, alice);
    expect(game.scoreOf(bob).remaining, 456);
  });

  test('301 starts everyone on 301', () {
    final session = newSession()
      ..startGame([alice, bob], config: const X01Config(startScore: 301));
    expect(session.state.game!.scores.map((s) => s.remaining), [301, 301]);
  });

  test('Alice and Bob, 501: Alice checks out exactly and wins', () {
    final session = newSession()..startGame([alice, bob]);
    play(session, [180, 60, 180, 60]);
    checkOut(session, 141);

    final game = session.state.game!;
    expect(game.scoreOf(alice).remaining, 0);
    expect(game.isFinished, isTrue);
    expect(game.winner, alice);
  });

  test('going below zero is a bust: nothing scored, turn passes', () {
    final session = newSession()
      ..startGame([alice, bob], config: const X01Config(startScore: 301));
    play(session, [180, 0, 140]);

    final game = session.state.game!;
    expect(game.scoreOf(alice).remaining, 121);
    expect(game.scoreOf(alice).lastVisit!.isBust, isTrue);
    expect(game.scoreOf(alice).lastVisit!.points, 0);
    expect(game.activePlayer, bob);
    expect(game.isFinished, isFalse);
  });

  group('rejections leave the state untouched', () {
    test('a visit without a game', () {
      final session = newSession();
      expect(session.submitVisitTotal(60), isA<Rejected>());
      expect(session.state.game, isNull);
    });

    test('a total outside 0..180', () {
      final session = newSession()..startGame([alice, bob]);
      final before = scoreboardOf(session);

      expect(session.submitVisitTotal(181), isA<Rejected>());
      expect(session.submitVisitTotal(-1), isA<Rejected>());
      expect(scoreboardOf(session), before);
    });

    test('a visit after the game is over', () {
      final session = newSession()
        ..startGame([alice, bob], config: const X01Config(startScore: 301));
      play(session, [180, 0]);
      checkOut(session, 121);
      final before = scoreboardOf(session);

      expect(session.submitVisitTotal(60), isA<Rejected>());
      expect(scoreboardOf(session), before);
    });

    test('a new game while one is in progress', () {
      final session = newSession()..startGame([alice, bob]);
      play(session, [60]);
      final before = scoreboardOf(session);

      expect(session.startGame([bob, alice]), isA<Rejected>());
      expect(scoreboardOf(session), before);
    });

    test('a start score that cannot be finished', () {
      final session = newSession();
      expect(
        session.startGame([alice], config: const X01Config(startScore: 0)),
        isA<Rejected>(),
      );
      expect(session.state.game, isNull);
    });

    test('a game without players', () {
      final session = newSession();
      expect(session.startGame([]), isA<Rejected>());
      expect(session.state.game, isNull);
    });
  });

  test('a new game can start once the previous one is over', () {
    final session = newSession()
      ..startGame([alice, bob], config: const X01Config(startScore: 301));
    play(session, [180, 0]);
    checkOut(session, 121);

    expect(session.startGame([bob, alice]), isA<Accepted>());
    expect(session.state.game!.activePlayer, bob);
    expect(session.state.game!.isFinished, isFalse);
  });

  group('starting a session from the setup', () {
    const players = [
      Player(id: 'c', name: 'Chloé'),
      Player(id: 'a', name: 'Alice'),
      Player(id: 'b', name: 'Bob'),
    ];

    test('the first game follows the chosen order and config', () {
      final session = newSession();
      session.startGame(
        players,
        config: const X01Config(startScore: 301, outRule: OutRule.straight),
      );

      final game = session.state.game!;
      expect(game.scores.map((s) => s.player), players);
      expect(game.activePlayer.name, 'Chloé');
      expect(game.config.startScore, 301);
      expect(game.config.outRule, OutRule.straight);
    });

    test('at most $maxPlayers players', () {
      final nine = [
        for (var i = 0; i < maxPlayers + 1; i++) Player(id: '$i', name: 'P$i'),
      ];
      expect(newSession().startGame(nine), isA<Rejected>());
      expect(
        newSession().startGame(nine.take(maxPlayers).toList()),
        isA<Accepted>(),
      );
    });

    test('a player cannot play twice in the same game', () {
      expect(newSession().startGame([alice, bob, alice]), isA<Rejected>());
    });
  });
}
