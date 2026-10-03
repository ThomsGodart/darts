import 'package:darts_points_counter/soiree/soiree.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const chloe = Player(id: 'chloe', name: 'Chloé');
const dan = Player(id: 'dan', name: 'Dan');

/// A 40 double-out game: one D20 wins it.
const forty = X01Config(startScore: 40);

/// A soirée whose first 40 double-out game Alice wins with D20.
Soiree afterAliceWins({List<Player> players = const [alice, bob]}) {
  final soiree = newSoiree()..startGame(players, config: forty);
  checkOut(soiree, 40, darts: 1);
  return soiree;
}

List<Player> orderOf(Soiree soiree) => [
  for (final s in soiree.state.game!.scores) s.player,
];

void main() {
  group('Rejouer', () {
    test('starts the same game with the next player first', () {
      final soiree = afterAliceWins(players: [alice, bob, chloe]);

      expect(soiree.rematch(), isA<Accepted>());

      final game = soiree.state.game!;
      expect(orderOf(soiree), [bob, chloe, alice]);
      expect(game.activePlayer, bob);
      expect(game.config, const X01Config(startScore: 40));
      expect(game.isFinished, isFalse);
      expect(game.scores.every((s) => s.remaining == 40), isTrue);
    });

    test('the first player keeps rotating game after game', () {
      final soiree = afterAliceWins(players: [alice, bob, chloe]);
      final firsts = <Player>[];
      for (var i = 0; i < 3; i++) {
        soiree.rematch();
        firsts.add(soiree.state.game!.activePlayer);
        checkOut(soiree, 40, darts: 1);
      }
      expect(firsts, [bob, chloe, alice]);
    });

    test('with a new config', () {
      final soiree = afterAliceWins();
      const config = X01Config(startScore: 301, outRule: OutRule.straight);

      soiree.rematch(config: config);
      expect(soiree.state.game!.config, config);
    });

    test('refused while a game is in progress', () {
      final soiree = newSoiree()..startGame([alice, bob]);
      expect(soiree.rematch(), isA<Rejected>());
    });

    test('refused before any game', () {
      expect(newSoiree().rematch(), isA<Rejected>());
    });

    test('the checkout of the previous game can no longer be undone', () {
      final soiree = afterAliceWins()..rematch();
      expect(soiree.canUndo, isFalse);
    });
  });

  group('players between games', () {
    test('a late player joins the next game', () {
      final soiree = afterAliceWins();
      expect(soiree.startGame([bob, alice, chloe]), isA<Accepted>());
      expect(orderOf(soiree), [bob, alice, chloe]);
    });

    test('a player who left is out of the next games', () {
      final soiree = afterAliceWins(players: [alice, bob, chloe]);
      soiree.startGame([chloe, alice], config: forty);
      checkOut(soiree, 40, darts: 1);

      soiree.rematch();
      expect(orderOf(soiree), [alice, chloe]);
    });

    test('Rejouer after the first player left: the next one starts', () {
      final soiree = afterAliceWins(players: [alice, bob, chloe]);
      soiree.startGame([alice, bob, chloe, dan], config: forty);
      checkOut(soiree, 40, darts: 1);
      // Alice started and leaves: rotate from the order without her.
      soiree.startGame([bob, chloe, dan], config: forty);
      checkOut(soiree, 40, darts: 1);

      soiree.rematch();
      expect(soiree.state.game!.activePlayer, chloe);
    });

    test('players cannot change during a game', () {
      final soiree = newSoiree()..startGame([alice, bob]);
      expect(soiree.startGame([alice, bob, chloe]), isA<Rejected>());
    });
  });

  group('the soirée', () {
    test('lists its games in order, each with its winner', () {
      final soiree = afterAliceWins()..rematch();
      checkOut(soiree, 40, darts: 1);

      final games = soiree.state.games;
      expect(games, hasLength(2));
      expect([for (final g in games) g.winner], [alice, bob]);
      expect(soiree.state.game, games.last);
    });

    test('averages each player over all their games', () {
      final soiree = newSoiree()
        ..startGame([alice, bob], config: const X01Config(startScore: 101));
      play(soiree, [60, 60]);
      checkOut(soiree, 41, darts: 2); // Alice: 101 in 5 darts
      soiree.rematch(); // Bob first
      play(soiree, [0, 0]);
      checkOut(soiree, 101, darts: 3); // Bob: 60 + 101 in 3 + 6 darts

      final state = soiree.state;
      expect(state.averageOf(alice), (101 + 0) / (5 + 3) * 3);
      expect(state.averageOf(bob), (60 + 101) / (3 + 6) * 3);
      expect(state.averageOf(chloe), isNull);
    });

    test('ends explicitly between games', () {
      final soiree = afterAliceWins();
      expect(soiree.endSoiree(), isA<Accepted>());
      expect(soiree.state.isEnded, isTrue);

      expect(soiree.rematch(), isA<Rejected>());
      expect(soiree.startGame([alice, bob]), isA<Rejected>());
      expect(soiree.canUndo, isFalse);
    });

    test('cannot end in the middle of a game', () {
      final soiree = newSoiree()..startGame([alice, bob]);
      expect(soiree.endSoiree(), isA<Rejected>());
      expect(soiree.state.isEnded, isFalse);
    });

    test('ending twice is refused', () {
      final soiree = afterAliceWins()..endSoiree();
      expect(soiree.endSoiree(), isA<Rejected>());
    });
  });
}
