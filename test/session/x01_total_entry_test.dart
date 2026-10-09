import 'package:darts_points_counter/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

X01TotalEntry entryOn(
  int remaining,
  int score, {
  OutRule outRule = OutRule.double,
  bool trackDoubles = false,
}) {
  final session = newSession()
    ..startGame(
      [alice, bob],
      config: X01Config(
        startScore: remaining,
        outRule: outRule,
        trackDoubles: trackDoubles,
      ),
    );
  return X01TotalEntry(session.state.x01!, score);
}

void main() {
  test('a total far from a finish raises no question', () {
    final entry = entryOn(501, 60, trackDoubles: true);

    expect(entry.question, isNull);
    expect(entry.missedFinish, isFalse);
    expect(entry.dartsAtCheckout, isNull);
    expect(entry.dartsAtDouble, isNull);
  });

  group('a total that reaches 0', () {
    test('is first asked whether its last dart finishes', () {
      final entry = entryOn(40, 40);
      expect(
        entry.question,
        isA<FinishingDartQuestion>().having(
          (q) => q.outRule,
          'outRule',
          OutRule.double,
        ),
      );
    });

    test('busts on a no, with nothing more to ask', () {
      final entry = entryOn(40, 40, trackDoubles: true).finishingDart(false);

      expect(entry.question, isNull);
      expect(entry.missedFinish, isTrue);
      expect(entry.dartsAtCheckout, isNull);
      expect(entry.dartsAtDouble, isNull);
    });

    test('is then asked its darts, when several counts are possible', () {
      final entry = entryOn(40, 40).finishingDart(true);

      expect(
        entry.question,
        isA<CheckoutDartsQuestion>().having((q) => q.options, 'options', [
          1,
          2,
          3,
        ]),
      );
      final answered = entry.checkoutIn(2);
      expect(answered.question, isNull);
      expect(answered.dartsAtCheckout, 2);
      expect(answered.missedFinish, isFalse);
    });

    test('is not asked a count it can only be', () {
      // 170 takes all three darts.
      final entry = entryOn(170, 170).finishingDart(true);

      expect(entry.question, isNull);
      expect(entry.dartsAtCheckout, 3);
    });

    test('in straight-out, any dart finishes: only the count is asked', () {
      final entry = entryOn(40, 40, outRule: OutRule.straight);

      expect(entry.question, isA<CheckoutDartsQuestion>());
    });

    test('is asked its darts at a double last, when the game tracks them', () {
      final entry = entryOn(
        40,
        40,
        trackDoubles: true,
      ).finishingDart(true).checkoutIn(2);

      expect(
        entry.question,
        isA<DoubleDartsQuestion>().having((q) => q.options, 'options', [1, 2]),
      );
      final answered = entry.atDouble(1);
      expect(answered.question, isNull);
      expect((answered.dartsAtCheckout, answered.dartsAtDouble), (2, 1));
    });

    test('checked out in one dart, that dart was the one at a double', () {
      final entry = entryOn(
        40,
        40,
        trackDoubles: true,
      ).finishingDart(true).checkoutIn(1);

      expect(entry.question, isNull);
      expect(entry.dartsAtDouble, 1);
    });
  });

  test('near a finish, a game that tracks doubles asks how many', () {
    final entry = entryOn(40, 20, trackDoubles: true);

    expect(
      entry.question,
      isA<DoubleDartsQuestion>().having((q) => q.options, 'options', [
        0,
        1,
        2,
        3,
      ]),
    );
    expect(entry.atDouble(0).question, isNull);
    expect(entry.atDouble(0).dartsAtDouble, 0);
  });

  test('a game that does not track doubles is not asked about them', () {
    expect(entryOn(40, 20).question, isNull);
  });

  test('what was answered is what the session accepts', () {
    final session = newSession()
      ..startGame([
        alice,
        bob,
      ], config: const X01Config(startScore: 40, trackDoubles: true));
    final entry = X01TotalEntry(
      session.state.x01!,
      40,
    ).finishingDart(true).checkoutIn(3).atDouble(2);

    expect(entry.submitTo(session.submitVisitTotal), isA<Accepted>());
    expect(session.state.game!.winner, alice);
  });
}
