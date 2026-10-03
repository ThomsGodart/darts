import 'package:darts_points_counter/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const doubleOut301 = X01Config(startScore: 301);
const straightOut301 = X01Config(startScore: 301, outRule: OutRule.straight);

GameState gameOf(Session session) => session.state.game!;

/// Totals no combination of three darts can make.
const impossibleTotals = {179, 178, 176, 175, 173, 172, 169, 166, 163};

void main() {
  test('a new game defaults to 501 double-out', () {
    const config = X01Config();
    expect(config.startScore, 501);
    expect(config.outRule, OutRule.double);
  });

  group('busts', () {
    test('below zero: remaining restored, turn passes, bust visible', () {
      final session = newSession()
        ..startGame([alice, bob], config: doubleOut301);
      play(session, [180, 0, 140]);

      final alices = gameOf(session).scoreOf(alice);
      expect(alices.remaining, 121);
      expect(alices.lastVisit!.isBust, isTrue);
      expect(gameOf(session).activePlayer, bob);
    });

    test('double-out: leaving 1 is a bust', () {
      final session = newSession()
        ..startGame([alice, bob], config: doubleOut301);
      play(session, [180, 0, 120]);

      expect(gameOf(session).scoreOf(alice).remaining, 121);
      expect(gameOf(session).scoreOf(alice).lastVisit!.isBust, isTrue);
    });

    test('straight-out: leaving 1 is fine', () {
      final session = newSession()
        ..startGame([alice, bob], config: straightOut301);
      play(session, [180, 0, 120]);

      expect(gameOf(session).scoreOf(alice).remaining, 1);
      expect(gameOf(session).scoreOf(alice).lastVisit!.isBust, isFalse);
    });

    test('a bust does not end the game', () {
      final session = newSession()
        ..startGame([alice, bob], config: doubleOut301);
      play(session, [180, 0, 140]);
      expect(gameOf(session).isFinished, isFalse);
    });
  });

  group('visit totals', () {
    test('totals impossible with three darts are refused', () {
      for (final impossible in impossibleTotals) {
        final session = newSession()..startGame([alice, bob]);
        expect(
          session.submitVisitTotal(impossible),
          isA<Rejected>(),
          reason: '$impossible',
        );
        expect(gameOf(session).scoreOf(alice).remaining, 501);
      }
    });

    test('every other total from 0 to 180 is accepted', () {
      for (var total = 0; total <= 180; total++) {
        if (impossibleTotals.contains(total)) continue;
        final session = newSession()..startGame([alice, bob]);
        expect(
          session.submitVisitTotal(total),
          isA<Accepted>(),
          reason: '$total',
        );
      }
    });
  });

  group('checkouts', () {
    test('a checkout needs the number of darts used', () {
      final session = newSession()
        ..startGame([alice, bob], config: doubleOut301);
      play(session, [180, 0]);
      final before = scoreboardOf(session);

      expect(session.submitVisitTotal(121), isA<Rejected>());
      expect(scoreboardOf(session), before);

      checkOut(session, 121, darts: 3);
      expect(gameOf(session).winner, alice);
    });

    test('a dart count is refused on a visit that does not check out', () {
      final session = newSession()..startGame([alice, bob]);
      expect(session.submitVisitTotal(60, dartsAtCheckout: 3), isA<Rejected>());
    });

    test('a checkout in fewer darts than possible is refused', () {
      final session = newSession()
        ..startGame([alice, bob], config: doubleOut301);
      play(session, [180, 0]);

      // 121 double-out needs three darts (e.g. T20 T11 D14).
      expect(
        session.submitVisitTotal(121, dartsAtCheckout: 2),
        isA<Rejected>(),
      );
      expect(gameOf(session).isFinished, isFalse);
    });

    test('dart count options follow what the remaining allows', () {
      final session = newSession()
        ..startGame([alice, bob], config: doubleOut301);
      play(session, [180, 0]);
      final game = gameOf(session);

      expect(game.checkoutDartOptions(121), [3]);
      expect(game.checkoutDartOptions(60), isEmpty, reason: 'not a checkout');
    });

    test('dart count options for typical double-out finishes', () {
      final cases = {
        40: [1, 2, 3],
        100: [2, 3],
        50: [1, 2, 3],
        170: [3],
      };
      for (final MapEntry(key: remaining, value: options) in cases.entries) {
        final session = newSession()
          ..startGame([alice], config: X01Config(startScore: remaining));
        expect(
          gameOf(session).checkoutDartOptions(remaining),
          options,
          reason: '$remaining',
        );
      }
    });

    test('impossible double-out finishes cannot end the game', () {
      // Above 170 nothing finishes on a double, even if three darts can
      // score it (174, 177, 180).
      for (final remaining in [168, 165, 162, 159, 171, 174, 177, 180]) {
        final session = newSession()
          ..startGame([alice], config: X01Config(startScore: remaining));
        expect(gameOf(session).checkoutDartOptions(remaining), isEmpty);
        expect(
          session.submitVisitTotal(remaining, dartsAtCheckout: 3),
          isA<Rejected>(),
          reason: '$remaining',
        );
        expect(gameOf(session).scoreOf(alice).remaining, remaining);
      }
    });

    test('straight-out finishes on any dart', () {
      final session = newSession()
        ..startGame([
          alice,
        ], config: const X01Config(startScore: 168, outRule: OutRule.straight));
      expect(gameOf(session).checkoutDartOptions(168), [3]);
      checkOut(session, 168);
      expect(gameOf(session).winner, alice);
    });

    test('straight-out 1 can be finished with a single dart', () {
      final session = newSession()
        ..startGame([
          alice,
        ], config: const X01Config(startScore: 3, outRule: OutRule.straight));
      expect(gameOf(session).checkoutDartOptions(3), [1, 2, 3]);
    });
  });

  group('three-dart average', () {
    test('nothing before the first visit', () {
      final session = newSession()..startGame([alice, bob]);
      expect(gameOf(session).scoreOf(alice).threeDartAverage, isNull);
    });

    test('Alice 180, 180, 141 checked out in 3 darts averages 167', () {
      final session = newSession()..startGame([alice, bob]);
      play(session, [180, 0, 180, 0]);
      checkOut(session, 141, darts: 3);

      expect(gameOf(session).scoreOf(alice).threeDartAverage, 167);
      expect(gameOf(session).scoreOf(bob).threeDartAverage, 0);
    });

    test('checking out in 2 darts counts 2 darts', () {
      final session = newSession()
        ..startGame([alice, bob], config: doubleOut301);
      play(session, [180, 0, 21, 0]);
      checkOut(session, 100, darts: 2);

      // 301 points in 3 + 3 + 2 = 8 darts.
      expect(gameOf(session).scoreOf(alice).threeDartAverage, 301 / 8 * 3);
    });

    test('a bust scores nothing but its three darts count', () {
      final session = newSession()
        ..startGame([alice, bob], config: doubleOut301);
      play(session, [180, 0, 140]);

      expect(gameOf(session).scoreOf(alice).threeDartAverage, 90);
    });
  });
}
