import 'package:darts_points_counter/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exhaustive rather than sampled: every cricket number, every pair of
/// darts on it, every thrower, in one visit or across two.
void main() {
  final players = [for (var i = 0; i < 3; i++) Player(id: '$i', name: 'P$i')];

  Dart dartOn(int number, int multiplier) =>
      Dart.fromStored(sector: number, multiplier: multiplier);

  test('marks past the third score for the thrower while others are open', () {
    final failures = <String>[];
    for (final count in [2, 3]) {
      for (var thrower = 0; thrower < count; thrower++) {
        for (final number in cricketNumbers) {
          final multipliers = number == Dart.bullSector ? [1, 2] : [1, 2, 3];
          for (final first in multipliers) {
            for (final second in multipliers) {
              for (final acrossVisits in [false, true]) {
                final session = Session(InMemoryJournal())
                  ..startGame(
                    players.take(count).toList(),
                    config: const CricketConfig(),
                  );
                for (var i = 0; i < thrower; i++) {
                  session.endVisit();
                }
                session.throwDart(dartOn(number, first));
                if (acrossVisits) {
                  // Everyone, the thrower first, ends their visit.
                  for (var i = 0; i < count; i++) {
                    session.endVisit();
                  }
                }
                session.throwDart(dartOn(number, second));

                final game = session.state.game! as CricketGame;
                final expected =
                    (first + second - marksToClose).clamp(0, 3) * number;
                final points = game.scores[thrower].points;
                if (points != expected) {
                  failures.add(
                    '$count players, thrower $thrower, $number: '
                    '$first then $second '
                    '${acrossVisits ? 'next visit' : 'same visit'} '
                    '→ $points, expected $expected',
                  );
                }
              }
            }
          }
        }
      }
    }
    expect(failures, isEmpty, reason: failures.take(10).join('\n'));
  });
}
