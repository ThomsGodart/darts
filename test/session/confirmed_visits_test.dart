import 'package:darts_points_counter/session/event_codec.dart';
import 'package:darts_points_counter/session/events.dart';
import 'package:darts_points_counter/session/fold.dart';
import 'package:darts_points_counter/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  const t20 = Dart.treble(20);

  group('a visit waits to be ended after its last dart', () {
    test('in cricket the marks show while the thrower is still up', () {
      final session = newSession()
        ..startGame([alice, bob], config: const CricketConfig())
        ..throwDart(t20)
        ..throwDart(t20)
        ..throwDart(Dart.miss);

      final game = session.state.game! as CricketGame;
      expect(game.activePlayer, alice);
      expect(game.visitIsOver, isTrue);
      expect(game.scoreOf(alice).points, 60);
      expect(game.roundsOf(alice), 1);

      session.endVisit();
      expect(session.state.game!.activePlayer, bob);
      expect(session.state.game!.dartsInVisit, isEmpty);
    });

    test('the last visit of a game by rounds needs ending too', () {
      final session = newSession()
        ..startGame([alice], config: const CountUpConfig(rounds: 8));
      for (var round = 1; round <= 8; round++) {
        session
          ..throwDart(t20)
          ..throwDart(t20)
          ..throwDart(t20);
        expect(session.state.game!.isFinished, isFalse);
        session.endVisit();
      }
      expect(session.state.game!.winner, alice);
    });

    test('a dart that wins ends the game without waiting', () {
      final session = newSession()
        ..startGame([alice, bob], config: const X01Config(startScore: 40))
        ..throwDart(const Dart.double(20));
      expect(session.state.game!.winner, alice);
    });

    test('undo reopens the visit that was ended, darts and all', () {
      final session = newSession()
        ..startGame([alice, bob])
        ..throwDart(t20)
        ..throwDart(t20)
        ..throwDart(t20);
      final before = scoreboardOf(session);
      session
        ..endVisit()
        ..undo();
      expect(scoreboardOf(session), before);
    });
  });

  test('a visit entered dart by dart keeps its darts', () {
    final session = newSession()
      ..startGame([alice, bob])
      ..throwDart(t20)
      ..throwDart(const Dart.single(5))
      ..endVisit()
      ..submitVisitTotal(60);

    final game = session.state.x01!;
    expect(game.scoreOf(alice).lastVisit!.thrown, [t20, const Dart.single(5)]);
    expect(game.scoreOf(alice).lastVisit!.darts, 3);
    expect(game.scoreOf(bob).lastVisit!.thrown, isEmpty);
  });

  group('a total that reaches 0 without its finish', () {
    test('busts when the players say so', () {
      final session = newSession()
        ..startGame([alice, bob], config: const X01Config(startScore: 40));

      expect(session.submitVisitTotal(40, missedFinish: true), isA<Accepted>());
      final game = session.state.x01!;
      expect(game.winner, isNull);
      expect(game.scoreOf(alice).remaining, 40);
      expect(game.scoreOf(alice).lastVisit!.isBust, isTrue);
      expect(game.activePlayer, bob);
    });

    test('survives being stored', () {
      const event = VisitTotalSubmitted(40, isBust: true);
      final stored = encodeEvent(event);
      final back = decodeEvent(stored.type, stored.payload);
      expect((back as VisitTotalSubmitted).isBust, isTrue);
    });

    test('is refused on any other total, and in straight-out', () {
      final session = newSession()
        ..startGame([alice], config: const X01Config(startScore: 40));
      expect(session.submitVisitTotal(20, missedFinish: true), isA<Rejected>());

      final straight = newSession()
        ..startGame([
          alice,
        ], config: const X01Config(startScore: 40, outRule: OutRule.straight));
      expect(
        straight.submitVisitTotal(40, missedFinish: true),
        isA<Rejected>(),
      );
    });
  });

  group('a game journaled before visits were confirmed', () {
    final legacy = [
      const GameStarted(
        players: [alice, bob],
        config: CricketConfig(),
        confirmsVisits: false,
      ),
      const DartThrown(t20),
      const DartThrown(t20),
      const DartThrown(Dart.miss),
      // Bob passes without a dart.
      const VisitEnded(),
      const DartThrown(Dart.treble(19)),
    ];

    test('still passes the turn on the third dart', () {
      final game = foldEvents(legacy).game! as CricketGame;
      expect(game.activePlayer, alice);
      expect(game.dartsInVisit, [const Dart.treble(19)]);
      expect(game.scoreOf(bob).visitsPlayed, 1);
    });

    test('is told apart once stored', () {
      final old = encodeEvent(legacy.first);
      expect(old.payload.containsKey('confirmsVisits'), isFalse);
      final back = decodeEvent(old.type, old.payload) as GameStarted;
      expect(back.confirmsVisits, isFalse);

      final fresh = encodeEvent(
        const GameStarted(players: [alice], config: X01Config()),
      );
      final freshBack = decodeEvent(fresh.type, fresh.payload) as GameStarted;
      expect(freshBack.confirmsVisits, isTrue);
    });
  });
}
