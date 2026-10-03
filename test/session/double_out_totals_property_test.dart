import 'package:darts_points_counter/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  test('double-out, typed totals: a bust exactly when below 0 or on 1', () {
    final surprises = <String>[];
    for (var remaining = 2; remaining <= 501; remaining++) {
      for (var total = 0; total <= 180; total++) {
        final session = newSession()
          ..startGame([alice, bob], config: X01Config(startScore: remaining));
        final game = session.state.game!;
        final options = game.checkoutDartOptions(total);
        final result = session.submitVisitTotal(
          total,
          dartsAtCheckout: options.isEmpty ? null : options.first,
        );
        if (result is Rejected) continue; // impossible totals or finishes
        final visit = session.state.game!.scoreOf(alice).lastVisit!;
        final after = remaining - total;
        final shouldBust = after < 0 || after == 1;
        if (visit.isBust != shouldBust) {
          surprises.add('$remaining - $total → bust ${visit.isBust}');
        }
      }
    }
    expect(surprises, isEmpty);
  });
}
