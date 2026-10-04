import 'package:darts_points_counter/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const miss = Dart.miss;

/// One visit: [darts], then the turn is passed.
void visit(Session session, [List<Dart> darts = const []]) {
  final visits = session.state.game!.visitsPlayed;
  for (final dart in darts) {
    if (session.state.game!.isFinished) return;
    expect(session.throwDart(dart), isA<Accepted>(), reason: '$dart');
  }
  final game = session.state.game!;
  if (!game.isFinished && game.visitsPlayed == visits) session.endVisit();
}

void main() {
  group('Around the Clock', () {
    AroundTheClockGame gameOf(Session s) => s.state.game! as AroundTheClockGame;

    test('everyone starts on 1; any ring of the number moves on', () {
      final session = newSession()
        ..startGame([
          alice,
          bob,
        ], config: const AroundTheClockConfig(finishOnBull: false));
      expect(gameOf(session).activeTarget, 1);

      visit(session, [
        const Dart.single(1),
        const Dart.treble(2),
        const Dart.double(3),
      ]);

      expect(gameOf(session).scoreOf(alice).hits, 3);
      expect(gameOf(session).targetOf(gameOf(session).scoreOf(alice)), 4);
      expect(gameOf(session).activePlayer, bob);
      expect(gameOf(session).activeTarget, 1);
    });

    test('a dart on another number does not move on', () {
      final session = newSession()
        ..startGame([
          alice,
        ], config: const AroundTheClockConfig(finishOnBull: false));
      visit(session, [const Dart.single(2), miss, const Dart.single(20)]);
      expect(gameOf(session).scoreOf(alice).hits, 0);
    });

    test('without the bull, the first to hit 20 wins at once', () {
      final session = newSession()
        ..startGame([
          alice,
          bob,
        ], config: const AroundTheClockConfig(finishOnBull: false));
      for (var n = 1; n <= 18; n += 3) {
        visit(session, [for (var k = n; k < n + 3; k++) Dart.single(k)]);
        visit(session);
      }
      session
        ..throwDart(const Dart.single(19))
        ..throwDart(const Dart.single(20));

      expect(gameOf(session).winner, alice);
      expect(session.throwDart(miss), isA<Rejected>());
    });

    test('the second player can win, on their first dart', () {
      final session = newSession()
        ..startGame([
          alice,
          bob,
        ], config: const AroundTheClockConfig(finishOnBull: false));
      for (var n = 1; n <= 19; n++) {
        if (session.state.game!.activePlayer == alice) visit(session);
        session.throwDart(Dart.single(n));
        if ((n % 3) == 0) continue;
      }
      // Bob is on 20; let the turn come back to him.
      while (session.state.game!.activePlayer != bob ||
          session.state.game!.dartsInVisit.isNotEmpty) {
        visit(session);
      }
      session.throwDart(const Dart.treble(20));

      expect(gameOf(session).winner, bob);
      session.undo();
      expect(gameOf(session).isFinished, isFalse);
    });

    test('the bull finishes the round unless asked otherwise', () {
      expect(const AroundTheClockConfig().finishOnBull, isTrue);
      expect(const AroundTheClockConfig().targets, 21);
    });

    test('with the bull to finish, 20 is not the end', () {
      final session = newSession()
        ..startGame([
          alice,
        ], config: const AroundTheClockConfig(finishOnBull: true));
      for (var n = 1; n <= 20; n++) {
        session.throwDart(Dart.single(n));
      }
      expect(gameOf(session).isFinished, isFalse);
      expect(gameOf(session).activeTarget, Dart.bullSector);

      session.throwDart(Dart.outerBull);
      expect(gameOf(session).winner, alice);
    });
  });

  group("Bob's 27", () {
    Bobs27Game gameOf(Session s) => s.state.game! as Bobs27Game;

    test('everyone starts on 27, aiming at double 1', () {
      final session = newSession()
        ..startGame([alice, bob], config: const Bobs27Config());
      expect(gameOf(session).scoreOf(alice).points, 27);
      expect(gameOf(session).currentTarget, const Dart.double(1));
    });

    test('each double hit adds its value; a visit without one costs it', () {
      final session = newSession()
        ..startGame([alice, bob], config: const Bobs27Config());
      visit(session, [const Dart.double(1), const Dart.double(1)]);
      visit(session, [const Dart.single(1)]);

      expect(gameOf(session).scoreOf(alice).points, 31);
      expect(gameOf(session).scoreOf(bob).points, 25);
      expect(gameOf(session).currentTarget, const Dart.double(2));
    });

    test('a player down to zero or less is out and skipped', () {
      final session = newSession()
        ..startGame([alice, bob], config: const Bobs27Config());
      // Alice misses D1..D5: 27 - 2 - 4 - 6 - 8 - 10 = -3.
      for (var n = 1; n <= 5; n++) {
        visit(session);
        visit(session, [Dart.double(n)]);
      }

      expect(gameOf(session).scoreOf(alice).isOut, isTrue);
      expect(gameOf(session).scoreOf(alice).points, -3);
      expect(gameOf(session).activePlayer, bob);
      expect(gameOf(session).currentTarget, const Dart.double(6));
      visit(session, [const Dart.double(6)]);
      expect(gameOf(session).activePlayer, bob);
      expect(gameOf(session).currentTarget, const Dart.double(7));
    });

    test('exactly zero is out too', () {
      final session = newSession()
        ..startGame([alice], config: const Bobs27Config());
      // 27 + 2 (one D1) - 4 - 6 - 8 - 10 = 1, then - 12 would overshoot:
      // aim for zero instead with 27 - 2 - 4 - 6 = 15, + 16 (two D4) = 31…
      visit(session, [const Dart.double(1)]); // 29
      visit(session); // 25
      visit(session); // 19
      visit(session); // 11
      visit(session); // 1
      expect(gameOf(session).scoreOf(alice).points, 1);
      expect(gameOf(session).isFinished, isFalse);
      visit(session); // -11
      expect(gameOf(session).scoreOf(alice).isOut, isTrue);
      expect(const Bobs27Score(player: alice, points: 0).isOut, isTrue);
    });

    test('three players: the order survives whoever goes out', () {
      const chloe = Player(id: 'chloe', name: 'Chloé');
      final session = newSession()
        ..startGame([alice, bob, chloe], config: const Bobs27Config());
      // Bob, in the middle, misses everything; the others hit once.
      for (var n = 1; n <= 5; n++) {
        visit(session, [Dart.double(n)]);
        visit(session);
        visit(session, [Dart.double(n)]);
      }
      expect(gameOf(session).scoreOf(bob).isOut, isTrue);
      expect(gameOf(session).activePlayer, alice);
      expect(gameOf(session).currentTarget, const Dart.double(6));

      visit(session, [const Dart.double(6)]);
      expect(gameOf(session).activePlayer, chloe);
      visit(session, [const Dart.double(6)]);
      expect(gameOf(session).activePlayer, alice);
      expect(gameOf(session).currentTarget, const Dart.double(7));
    });

    test('when everyone goes out, the last to fall wins', () {
      final session = newSession()
        ..startGame([alice, bob], config: const Bobs27Config());
      // Alice is out after D5 on -3; Bob hits D1 once and lasts longer,
      // ending lower.
      visit(session);
      visit(session, [const Dart.double(1)]);
      while (!gameOf(session).isFinished) {
        visit(session);
      }

      final game = gameOf(session);
      expect(game.scoreOf(alice).points, -3);
      expect(game.scoreOf(bob).points, lessThan(-3));
      expect(game.winner, bob);
    });

    test('the game ends once everyone is out', () {
      final session = newSession()
        ..startGame([alice], config: const Bobs27Config());
      for (var n = 1; n <= 5; n++) {
        visit(session);
      }
      expect(gameOf(session).isFinished, isTrue);
    });

    test('the bull is the last target; the highest score wins', () {
      final session = newSession()
        ..startGame([alice, bob], config: const Bobs27Config());
      for (var n = 1; n <= 20; n++) {
        visit(session, [Dart.double(n)]);
        visit(session, [Dart.double(n), Dart.double(n)]);
      }
      expect(gameOf(session).currentTarget, Dart.bull);
      visit(session, [Dart.bull]);
      expect(gameOf(session).isFinished, isFalse);
      visit(session, [Dart.outerBull]);

      final game = gameOf(session);
      expect(game.scoreOf(alice).points, 27 + 420 + 50);
      expect(game.scoreOf(bob).points, 27 + 840 - 50);
      expect(game.winner, bob);
    });
  });

  group('Count-Up', () {
    CountUpGame gameOf(Session s) => s.state.game! as CountUpGame;

    test('every dart scores what it is worth', () {
      final session = newSession()
        ..startGame([alice, bob], config: const CountUpConfig());
      visit(session, [const Dart.treble(20), const Dart.single(5), Dart.bull]);

      expect(gameOf(session).scoreOf(alice).points, 115);
      expect(gameOf(session).activePlayer, bob);
    });

    test('a visit can be entered as its total', () {
      final session = newSession()
        ..startGame([alice, bob], config: const CountUpConfig());
      expect(session.submitVisitTotal(140), isA<Accepted>());
      expect(session.submitVisitTotal(179), isA<Rejected>());

      expect(gameOf(session).scoreOf(alice).points, 140);
      expect(gameOf(session).activePlayer, bob);
    });

    test('after the last round, the highest total wins', () {
      const config = CountUpConfig();
      final session = newSession()..startGame([alice, bob], config: config);
      for (var round = 0; round < config.rounds; round++) {
        expect(gameOf(session).round, round + 1);
        session.submitVisitTotal(60);
        session.submitVisitTotal(100);
      }

      expect(gameOf(session).scoreOf(alice).points, 60 * config.rounds);
      expect(gameOf(session).winner, bob);
    });

    test('a total is refused once the visit has a dart', () {
      final session = newSession()
        ..startGame([alice, bob], config: const CountUpConfig());
      session.throwDart(const Dart.single(20));
      expect(session.submitVisitTotal(60), isA<Rejected>());

      session.endVisit();
      expect(gameOf(session).scoreOf(alice).points, 20);
      expect(gameOf(session).activePlayer, bob);
    });

    test('a tie goes to whoever threw first; undo reopens the game', () {
      const config = CountUpConfig(rounds: 10);
      final session = newSession()..startGame([alice, bob], config: config);
      for (var i = 0; i < 2 * config.rounds; i++) {
        session.submitVisitTotal(26);
      }
      expect(gameOf(session).winner, alice);

      session.undo();
      expect(gameOf(session).isFinished, isFalse);
      expect(gameOf(session).activePlayer, bob);
      expect(gameOf(session).round, 10);
    });

    test('eight or ten rounds', () {
      expect(const CountUpConfig().rounds, 8);
      expect(const CountUpConfig(rounds: 10).isValid, isTrue);
      expect(const CountUpConfig(rounds: 3).isValid, isFalse);
    });
  });

  group('Baseball', () {
    BaseballGame gameOf(Session s) => s.state.game! as BaseballGame;

    test('the inning is the number; single 1 run, double 2, treble 3', () {
      final session = newSession()
        ..startGame([alice, bob], config: const BaseballConfig());
      expect(gameOf(session).inning, 1);
      visit(session, [
        const Dart.single(1),
        const Dart.treble(1),
        const Dart.double(2),
      ]);

      expect(gameOf(session).scoreOf(alice).runs, 4);
      expect(gameOf(session).activePlayer, bob);
    });

    test('after nine innings, the most runs win', () {
      final session = newSession()
        ..startGame([alice, bob], config: const BaseballConfig());
      for (var inning = 1; inning <= 9; inning++) {
        visit(session, [Dart.single(inning)]);
        visit(session, [Dart.double(inning)]);
      }

      expect(gameOf(session).scoreOf(alice).runs, 9);
      expect(gameOf(session).winner, bob);
    });

    test('a tie behind the leader does not prolong the game', () {
      const chloe = Player(id: 'chloe', name: 'Chloé');
      final session = newSession()
        ..startGame([alice, bob, chloe], config: const BaseballConfig());
      for (var inning = 1; inning <= 9; inning++) {
        visit(session, [if (inning == 1) const Dart.single(1)]);
        visit(session);
        visit(session);
      }
      expect(gameOf(session).winner, alice);
    });

    test('at inning 20 a tie goes to whoever threw first', () {
      final session = newSession()
        ..startGame([alice, bob], config: const BaseballConfig());
      for (var inning = 1; inning <= baseballLastInning; inning++) {
        expect(gameOf(session).isFinished, isFalse);
        visit(session);
        visit(session);
      }
      expect(gameOf(session).winner, alice);
    });

    test('a tie for the lead goes to extra innings', () {
      final session = newSession()
        ..startGame([alice, bob], config: const BaseballConfig());
      for (var inning = 1; inning <= 9; inning++) {
        visit(session);
        visit(session);
      }
      expect(gameOf(session).isFinished, isFalse);
      expect(gameOf(session).inning, 10);

      visit(session);
      visit(session, [const Dart.single(10)]);
      expect(gameOf(session).winner, bob);
    });
  });
}
