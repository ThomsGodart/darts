import 'package:darts_points_counter/session/event_codec.dart';
import 'package:darts_points_counter/session/events.dart';
import 'package:darts_points_counter/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

X01Game gameOn(int remaining, {OutRule outRule = OutRule.double}) =>
    (newSession()..startGame([
          alice,
          bob,
        ], config: X01Config(startScore: remaining, outRule: outRule)))
        .state
        .x01!;

X01Stats statsOf(Player player, Session session) =>
    statsFor<X01Stats>(player, [session]);

void main() {
  group('entered dart by dart, darts at a double are counted', () {
    test('a dart thrown with a one-dart finish left is one', () {
      final session = newSession()
        ..startGame([alice, bob], config: const X01Config(startScore: 40));
      session
        ..throwDart(const Dart.single(20)) // at D20, leaves 20
        ..throwDart(Dart.miss) // at D10
        ..throwDart(const Dart.single(10)) // at D10, leaves 10
        ..endVisit();

      expect(session.state.x01!.scoreOf(alice).lastVisit!.dartsAtDouble, 3);
    });

    test('darts that set the finish up are not', () {
      final session = newSession()
        ..startGame([alice, bob], config: const X01Config(startScore: 100));
      session
        ..throwDart(const Dart.treble(20)) // 100: no one-dart finish
        ..throwDart(const Dart.double(20)); // at D20: checkout

      final visit = session.state.x01!.scoreOf(alice).lastVisit!;
      expect(visit.dartsAtDouble, 1);
      expect(session.state.game!.winner, alice);
    });

    test('the rate is checkouts over darts at a double', () {
      final session = newSession()
        ..startGame([alice], config: const X01Config(startScore: 40));
      session
        ..throwDart(Dart.miss)
        ..throwDart(Dart.miss)
        ..throwDart(Dart.miss)
        ..endVisit()
        ..throwDart(const Dart.double(20));

      final stats = statsOf(alice, session);
      expect(stats.dartsAtDouble, 4);
      expect(stats.checkouts, 1);
      expect(stats.checkoutRate, closeTo(0.25, 0.0001));
    });
  });

  group('entered as a total, they are only known if said', () {
    test('without a count, the visit says nothing of doubles', () {
      final session = newSession()
        ..startGame([alice], config: const X01Config(startScore: 40));
      checkOut(session, 40, darts: 2);

      expect(
        session.state.x01!.scoreOf(alice).lastVisit!.dartsAtDouble,
        isNull,
      );
      expect(statsOf(alice, session).checkoutRate, isNull);
    });

    test('with one, it counts', () {
      final session = newSession()
        ..startGame([alice, bob], config: const X01Config(startScore: 40));
      expect(session.submitVisitTotal(0, dartsAtDouble: 3), isA<Accepted>());
      session.submitVisitTotal(0);
      expect(
        session.submitVisitTotal(40, dartsAtCheckout: 1, dartsAtDouble: 1),
        isA<Accepted>(),
      );

      final stats = statsOf(alice, session);
      expect(stats.dartsAtDouble, 4);
      expect(stats.checkoutRate, closeTo(0.25, 0.0001));
      // Bob's visit carried no count: he has no rate.
      expect(statsOf(bob, session).checkoutRate, isNull);
    });

    test('a count that cannot be is refused', () {
      final session = newSession()
        ..startGame([alice], config: const X01Config(startScore: 40));
      expect(session.submitVisitTotal(0, dartsAtDouble: 4), isA<Rejected>());
      expect(session.submitVisitTotal(0, dartsAtDouble: -1), isA<Rejected>());
      // A checkout took at least one dart at a double, and no more than
      // the darts it took.
      expect(
        session.submitVisitTotal(40, dartsAtCheckout: 2, dartsAtDouble: 0),
        isA<Rejected>(),
      );
      expect(
        session.submitVisitTotal(40, dartsAtCheckout: 2, dartsAtDouble: 3),
        isA<Rejected>(),
      );
    });
  });

  group('which counts to offer for a total', () {
    test('none far from a finish', () {
      expect(gameOn(501).doubleDartOptions(60), isEmpty);
      expect(gameOn(180).doubleDartOptions(60), isEmpty);
    });

    test('0 to 3 when the visit started on a double', () {
      expect(gameOn(40).doubleDartOptions(0), [0, 1, 2, 3]);
      expect(gameOn(40).doubleDartOptions(20), [0, 1, 2, 3]);
    });

    test('fewer when darts were needed to get there', () {
      // 100 needs two darts: at most two at a double.
      expect(gameOn(100).doubleDartOptions(60), [0, 1, 2]);
      // 170 needs all three: at most one, and only on a visit that ends
      // on a finish or busts.
      expect(gameOn(170).doubleDartOptions(120), [0, 1]);
      expect(gameOn(170).doubleDartOptions(60), isEmpty);
    });

    test('a bust near a finish is asked about', () {
      expect(gameOn(100).doubleDartOptions(99), [0, 1, 2]);
    });

    test('a checkout took at least one, and no more than its darts allow', () {
      expect(gameOn(40).doubleDartOptions(40, dartsAtCheckout: 1), [1]);
      expect(gameOn(40).doubleDartOptions(40, dartsAtCheckout: 3), [1, 2, 3]);
      expect(gameOn(100).doubleDartOptions(100, dartsAtCheckout: 3), [1, 2]);
      expect(gameOn(100).doubleDartOptions(100, dartsAtCheckout: 2), [1]);
    });

    test('straight-out has no doubles to count', () {
      expect(
        gameOn(40, outRule: OutRule.straight).doubleDartOptions(0),
        isEmpty,
      );
    });
  });

  test('the count and the option are stored; old journals read without', () {
    const event = VisitTotalSubmitted(40, darts: 2, dartsAtDouble: 2);
    final encoded = encodeEvent(event);
    final back =
        decodeEvent(encoded.type, encoded.payload) as VisitTotalSubmitted;
    expect(back.dartsAtDouble, 2);

    final old = decodeEvent(encoded.type, {
      'score': 40,
      'darts': 2,
    }) as VisitTotalSubmitted;
    expect(old.dartsAtDouble, isNull);

    const config = X01Config(trackDoubles: true);
    final started = encodeEvent(
      const GameStarted(players: [alice], config: config),
    );
    expect(
      (decodeEvent(started.type, started.payload) as GameStarted).config,
      config,
    );
    expect(
      (decodeEvent(
        started.type,
        Map.of(started.payload)..remove('trackDoubles'),
      ) as GameStarted).config,
      const X01Config(),
    );
  });
}
