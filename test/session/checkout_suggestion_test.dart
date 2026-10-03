import 'package:darts_points_counter/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// A 1-player game where Alice has [remaining] left.
Session aliceOn(int remaining, {OutRule outRule = OutRule.double}) =>
    newSession()..startGame([
      alice,
    ], config: X01Config(startScore: remaining, outRule: outRule));

List<Dart>? suggestionFor(Session session) =>
    session.state.x01!.checkoutSuggestion;

int total(List<Dart> darts) => darts.fold(0, (sum, d) => sum + d.score);

void main() {
  group('double-out', () {
    test('170 is the big fish: T20 T20 Bull', () {
      expect(suggestionFor(aliceOn(170)), [
        Dart.treble(20),
        Dart.treble(20),
        Dart.bull,
      ]);
    });

    test('40 is a single dart at D20', () {
      expect(suggestionFor(aliceOn(40)), [Dart.double(20)]);
    });

    test('2 is D1, 3 is 1 then D1', () {
      expect(suggestionFor(aliceOn(2)), [Dart.double(1)]);
      expect(suggestionFor(aliceOn(3)), [Dart.single(1), Dart.double(1)]);
    });

    test('100 takes two darts, ending on a double', () {
      final route = suggestionFor(aliceOn(100))!;
      expect(route, hasLength(2));
      expect(total(route), 100);
      expect(route.last.isDouble, isTrue);
    });

    test('nothing for a remaining that cannot be checked out', () {
      for (final remaining in [169, 168, 159, 171, 301]) {
        expect(suggestionFor(aliceOn(remaining)), isNull, reason: '$remaining');
      }
    });

    test(
      'every finishable remaining from 2 to 170 gets a valid, shortest route',
      () {
        const noFinish = {169, 168, 166, 165, 163, 162, 159};
        for (var remaining = 2; remaining <= 170; remaining++) {
          final route = suggestionFor(aliceOn(remaining));
          if (noFinish.contains(remaining)) {
            expect(route, isNull, reason: '$remaining');
            continue;
          }
          expect(route, isNotNull, reason: '$remaining');
          expect(total(route!), remaining, reason: '$remaining');
          expect(route.last.isDouble, isTrue, reason: '$remaining');
          expect(route.every((d) => d.isValid && d != Dart.miss), isTrue);
          // Fewest darts: a 1-dart finish is never suggested in 2.
          final session = aliceOn(remaining);
          expect(
            session.state.x01!.checkoutDartOptions(remaining).first,
            route.length,
            reason: '$remaining',
          );
        }
      },
    );
  });

  group('during a visit entered dart by dart', () {
    test('the route follows the darts left', () {
      final session = aliceOn(100)..throwDart(Dart.treble(20));
      expect(suggestionFor(session), [Dart.double(20)]);
    });

    test('nothing when the darts left cannot finish', () {
      // 150 with two darts left: two darts make at most 110 on a double.
      final session = aliceOn(170)..throwDart(Dart.single(20));
      expect(suggestionFor(session), isNull);
    });

    test('a route for the last dart only', () {
      final session = aliceOn(100)
        ..throwDart(Dart.treble(20))
        ..throwDart(Dart.miss);
      expect(suggestionFor(session), [Dart.double(20)]);
    });
  });

  group('straight-out', () {
    test('the shortest route, on any dart', () {
      expect(suggestionFor(aliceOn(60, outRule: OutRule.straight)), [
        Dart.treble(20),
      ]);
      expect(
        suggestionFor(aliceOn(3, outRule: OutRule.straight)),
        hasLength(1),
      );
      expect(suggestionFor(aliceOn(170, outRule: OutRule.straight)), [
        Dart.treble(20),
        Dart.treble(20),
        Dart.bull,
      ]);
    });

    test('nothing above 170, as in double-out', () {
      for (final remaining in [171, 180, 181]) {
        expect(
          suggestionFor(aliceOn(remaining, outRule: OutRule.straight)),
          isNull,
          reason: '$remaining',
        );
      }
    });
  });

  test('no suggestion once the game is won', () {
    final session = aliceOn(40)..throwDart(Dart.double(20));
    expect(suggestionFor(session), isNull);
  });
}
