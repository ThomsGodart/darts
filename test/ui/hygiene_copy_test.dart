import 'package:darts_points_counter/session/session.dart';
import 'package:darts_points_counter/ui/game_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_test_harness.dart';
import '../game/game_screen_test.dart' show playVisits;

void main() {
  test('X01 config labels spell out the out rule', () {
    expect(configLabel(const X01Config()), '501 Double-out');
    expect(
      configLabel(const X01Config(outRule: OutRule.straight)),
      '501 Straight-out',
    );
  });

  testWidgets('game over offers Partie suivante and honest undo', (
    tester,
  ) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await launchGame(tester);
    await playVisits(tester, [180, 26, 180, 26, 141]);

    expect(find.text('Partie suivante'), findsOneWidget);
    expect(find.text('Changer…'), findsNothing);
    expect(find.text('Annuler le checkout'), findsOneWidget);
  });

  testWidgets('visit pad undo says Annuler la saisie', (tester) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await launchGame(tester);
    expect(find.text('Annuler la saisie'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(OutlinedButton),
        matching: find.text('Annuler'),
      ),
      findsNothing,
    );
  });
}
