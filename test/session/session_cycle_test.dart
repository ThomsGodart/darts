import 'package:darts_points_counter/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const chloe = Player(id: 'chloe', name: 'Chloé');
const dan = Player(id: 'dan', name: 'Dan');

/// A 40 double-out game: one D20 wins it.
const forty = X01Config(startScore: 40);

/// A session whose first 40 double-out game Alice wins with D20.
Session afterAliceWins({List<Player> players = const [alice, bob]}) {
  final session = newSession()..startGame(players, config: forty);
  checkOut(session, 40, darts: 1);
  return session;
}

List<Player> orderOf(Session session) => [
  for (final s in session.state.game!.scores) s.player,
];

void main() {
  group('Rejouer', () {
    test('starts the same game with the next player first', () {
      final session = afterAliceWins(players: [alice, bob, chloe]);

      expect(session.rematch(), isA<Accepted>());

      final game = session.state.game!;
      expect(orderOf(session), [bob, chloe, alice]);
      expect(game.activePlayer, bob);
      expect(game.config, const X01Config(startScore: 40));
      expect(game.isFinished, isFalse);
      expect(game.scores.every((s) => s.remaining == 40), isTrue);
    });

    test('the first player keeps rotating game after game', () {
      final session = afterAliceWins(players: [alice, bob, chloe]);
      final firsts = <Player>[];
      for (var i = 0; i < 3; i++) {
        session.rematch();
        firsts.add(session.state.game!.activePlayer);
        checkOut(session, 40, darts: 1);
      }
      expect(firsts, [bob, chloe, alice]);
    });

    test('with a new config', () {
      final session = afterAliceWins();
      const config = X01Config(startScore: 301, outRule: OutRule.straight);

      session.rematch(config: config);
      expect(session.state.game!.config, config);
    });

    test('refused while a game is in progress', () {
      final session = newSession()..startGame([alice, bob]);
      expect(session.rematch(), isA<Rejected>());
    });

    test('refused before any game', () {
      expect(newSession().rematch(), isA<Rejected>());
    });

    test('the checkout of the previous game can no longer be undone', () {
      final session = afterAliceWins()..rematch();
      expect(session.canUndo, isFalse);
    });
  });

  group('players between games', () {
    test('a late player joins the next game', () {
      final session = afterAliceWins();
      expect(session.startGame([bob, alice, chloe]), isA<Accepted>());
      expect(orderOf(session), [bob, alice, chloe]);
    });

    test('a player who left is out of the next games', () {
      final session = afterAliceWins(players: [alice, bob, chloe]);
      session.startGame([chloe, alice], config: forty);
      checkOut(session, 40, darts: 1);

      session.rematch();
      expect(orderOf(session), [alice, chloe]);
    });

    test('Rejouer after the first player left: the next one starts', () {
      final session = afterAliceWins(players: [alice, bob, chloe]);
      session.startGame([alice, bob, chloe, dan], config: forty);
      checkOut(session, 40, darts: 1);
      // Alice started and leaves: rotate from the order without her.
      session.startGame([bob, chloe, dan], config: forty);
      checkOut(session, 40, darts: 1);

      session.rematch();
      expect(session.state.game!.activePlayer, chloe);
    });

    test('players cannot change during a game', () {
      final session = newSession()..startGame([alice, bob]);
      expect(session.startGame([alice, bob, chloe]), isA<Rejected>());
    });
  });

  group('the session', () {
    test('lists its games in order, each with its winner', () {
      final session = afterAliceWins()..rematch();
      checkOut(session, 40, darts: 1);

      final games = session.state.games;
      expect(games, hasLength(2));
      expect([for (final g in games) g.winner], [alice, bob]);
      expect(session.state.game, games.last);
    });

    test('averages each player over all their games', () {
      final session = newSession()
        ..startGame([alice, bob], config: const X01Config(startScore: 101));
      play(session, [60, 60]);
      checkOut(session, 41, darts: 2); // Alice: 101 in 5 darts
      session.rematch(); // Bob first
      play(session, [0, 0]);
      checkOut(session, 101, darts: 3); // Bob: 60 + 101 in 3 + 6 darts

      final state = session.state;
      expect(state.averageOf(alice), (101 + 0) / (5 + 3) * 3);
      expect(state.averageOf(bob), (60 + 101) / (3 + 6) * 3);
      expect(state.averageOf(chloe), isNull);
    });

    test('ends explicitly between games', () {
      final session = afterAliceWins();
      expect(session.endSession(), isA<Accepted>());
      expect(session.state.isEnded, isTrue);

      expect(session.rematch(), isA<Rejected>());
      expect(session.startGame([alice, bob]), isA<Rejected>());
      expect(session.canUndo, isFalse);
    });

    test('can be abandoned mid-game; the game stays unfinished', () {
      final session = newSession()..startGame([alice, bob]);
      play(session, [60]);

      expect(session.endSession(), isA<Accepted>());
      expect(session.state.isEnded, isTrue);
      expect(session.state.game!.isFinished, isFalse);
      expect(session.submitVisitTotal(60), isA<Rejected>());
      expect(session.canUndo, isFalse);
    });

    test('a renamed player keeps one session average', () {
      final session = afterAliceWins();
      const alicia = Player(id: 'alice', name: 'Alicia');
      session.startGame([bob, alicia], config: forty);
      play(session, [0]);
      checkOut(session, 40, darts: 3);

      // 40 in 1 dart, then 40 in 3: one player, one average over 4 darts.
      expect(session.state.averageOf(alicia), 80 / 4 * 3);
      expect(session.state.averageOf(alice), 80 / 4 * 3);
    });

    test('ending twice is refused', () {
      final session = afterAliceWins()..endSession();
      expect(session.endSession(), isA<Rejected>());
    });

    test('its players, in the order they first played', () {
      final session = afterAliceWins()..startGame([chloe, bob, alice]);
      expect(session.state.players, [alice, bob, chloe]);
    });

    test(
      'a player renamed between games is listed once, with the new name',
      () {
        final session = afterAliceWins();
        const alicia = Player(id: 'alice', name: 'Alicia');
        session.startGame([bob, alicia], config: forty);
        expect(session.state.players, [alicia, bob]);
      },
    );
  });
}
