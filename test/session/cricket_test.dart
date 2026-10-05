import 'package:darts_points_counter/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const standard = CricketConfig();

CricketGame cricketOf(Session session) => session.state.game! as CricketGame;

const miss = Dart.miss;
const t20 = Dart.treble(20);

/// One visit for whoever is up: [darts], padded with misses to three.
void visit(Session session, [List<Dart> darts = const []]) {
  for (final dart in darts) {
    if (session.state.game!.isFinished) return;
    expect(session.throwDart(dart), isA<Accepted>(), reason: '$dart');
  }
  if (!session.state.game!.isFinished) session.endVisit();
}

/// Closes every number for whoever is up, over three visits each followed
/// by a miss visit for each other player.
void closeAll(Session session, int otherPlayers) {
  for (final darts in [
    [t20, const Dart.treble(19), const Dart.treble(18)],
    [const Dart.treble(17), const Dart.treble(16), const Dart.treble(15)],
    [Dart.bull, Dart.outerBull],
  ]) {
    visit(session, darts);
    if (session.state.game!.isFinished) return;
    for (var i = 0; i < otherPlayers; i++) {
      visit(session);
    }
  }
}

void main() {
  test('a new game: everyone on no marks and no points', () {
    final session = newSession()..startGame([alice, bob], config: standard);
    final game = cricketOf(session);

    expect(cricketNumbers, [20, 19, 18, 17, 16, 15, 25]);
    for (final number in cricketNumbers) {
      expect(game.scoreOf(alice).marksOn(number), 0);
    }
    expect(game.scoreOf(alice).points, 0);
    expect(game.activePlayer, alice);
  });

  group('marks', () {
    test('singles, doubles and trebles on 15–20', () {
      final session = newSession()..startGame([alice, bob], config: standard);
      visit(session, [t20, const Dart.double(19), const Dart.single(15)]);

      final alices = cricketOf(session).scoreOf(alice);
      expect(alices.marksOn(20), 3);
      expect(alices.marksOn(19), 2);
      expect(alices.marksOn(15), 1);
      expect(alices.isClosed(20), isTrue);
      expect(alices.isClosed(19), isFalse);
    });

    test('25 is one bull mark, the bull two', () {
      final session = newSession()..startGame([alice, bob], config: standard);
      visit(session, [Dart.outerBull, Dart.bull]);
      expect(cricketOf(session).scoreOf(alice).marksOn(25), 3);
    });

    test('1–14 and a miss are thrown but mark nothing', () {
      final session = newSession()..startGame([alice, bob], config: standard);
      visit(session, [const Dart.treble(14), const Dart.single(1), miss]);

      final game = cricketOf(session);
      for (final number in cricketNumbers) {
        expect(game.scoreOf(alice).marksOn(number), 0);
      }
      expect(game.activePlayer, bob, reason: 'three darts were thrown');
    });

    test('the visit in progress shows its darts until the third', () {
      final session = newSession()..startGame([alice, bob], config: standard);
      session.throwDart(t20);
      expect(cricketOf(session).dartsInVisit, [t20]);
      expect(cricketOf(session).activePlayer, alice);
    });
  });

  group('standard scoring', () {
    test('marks past a closed number score while an opponent is open', () {
      final session = newSession()..startGame([alice, bob], config: standard);
      visit(session, [t20]);
      visit(session);
      visit(session, [t20]);

      expect(cricketOf(session).scoreOf(alice).points, 60);
    });

    test('the dart that closes a number scores what it has left over', () {
      final session = newSession()..startGame([alice, bob], config: standard);
      visit(session, [const Dart.double(20), t20]);

      // 2 + 3 marks: the treble closes with 1 and scores 2 × 20.
      expect(cricketOf(session).scoreOf(alice).points, 40);
    });

    test('the bull scores 25 a mark', () {
      final session = newSession()..startGame([alice, bob], config: standard);
      visit(session, [Dart.bull, Dart.outerBull, Dart.bull]);
      expect(cricketOf(session).scoreOf(alice).points, 50);
    });

    test('a number closed by everyone is dead: no more points', () {
      final session = newSession()..startGame([alice, bob], config: standard);
      visit(session, [t20]);
      visit(session, [t20]);
      visit(session, [t20]);

      final game = cricketOf(session);
      expect(game.scoreOf(alice).points, 0);
      expect(game.isDead(20), isTrue);
      expect(game.isDead(19), isFalse);
    });
  });

  group('standard win', () {
    test('closing everything with the most points wins at once', () {
      final session = newSession()..startGame([alice, bob], config: standard);
      closeAll(session, 1);

      final game = cricketOf(session);
      expect(game.winner, alice);
      // The bull visit ended after two darts.
      expect(session.throwDart(miss), isA<Rejected>());
    });

    test('a tie on points still wins', () {
      final session = newSession()..startGame([alice, bob], config: standard);
      closeAll(session, 1);
      expect(cricketOf(session).winner, alice);
      expect(cricketOf(session).scoreOf(bob).points, 0);
    });

    test('closing everything behind on points does not win', () {
      final session = newSession()..startGame([alice, bob], config: standard);
      visit(session); // Alice
      visit(session, [t20, t20]); // Bob: 60 points on 20
      closeAll(session, 1); // Alice closes all, Bob keeps missing

      final game = cricketOf(session);
      expect(game.scoreOf(alice).isClosed(25), isTrue);
      expect(game.winner, isNull);

      // Alice scores on the 19 Bob has not closed, and wins.
      visit(session, [const Dart.treble(19), const Dart.single(19)]);
      expect(cricketOf(session).winner, alice);
    });

    test('nothing wins while a number is still open', () {
      final session = newSession()..startGame([alice], config: standard);
      visit(session, [t20, const Dart.treble(19), const Dart.treble(18)]);
      visit(session, [
        const Dart.treble(17),
        const Dart.treble(16),
        const Dart.treble(15),
      ]);
      visit(session, [Dart.bull]);
      expect(cricketOf(session).winner, isNull);
    });
  });

  group('undo and inputs', () {
    test('undo takes back darts across visits and after the win', () {
      final session = newSession()..startGame([alice, bob], config: standard);
      closeAll(session, 1);
      expect(cricketOf(session).winner, alice);

      session.undo();
      expect(cricketOf(session).winner, isNull);
      expect(cricketOf(session).scoreOf(alice).marksOn(25), 2);
      expect(cricketOf(session).activePlayer, alice);

      // Alice's bull, then the end of Bob's visit.
      session
        ..undo()
        ..undo();
      expect(cricketOf(session).activePlayer, bob);
    });

    test('visit totals are refused in cricket', () {
      final session = newSession()..startGame([alice, bob], config: standard);
      expect(session.submitVisitTotal(60), isA<Rejected>());
    });

    test('Rejouer keeps cricket and rotates the first player', () {
      final session = newSession()
        ..startGame([alice, bob, chloe], config: standard);
      closeAll(session, 2);
      session.rematch();

      final game = cricketOf(session);
      expect(game.config, standard);
      expect(game.activePlayer, bob);
      expect(game.scoreOf(alice).points, 0);
    });

    test('an X01 game then a cricket game in one session', () {
      final session = newSession()
        ..startGame([alice, bob], config: const X01Config(startScore: 40));
      checkOut(session, 40, darts: 1);
      session.startGame([bob, alice], config: standard);

      expect(session.state.games.first, isA<X01Game>());
      expect(session.state.game, isA<CricketGame>());
      expect(session.state.averageOf(alice), 120);
    });
  });
}

const chloe = Player(id: 'chloe', name: 'Chloé');
