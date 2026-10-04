import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_test_harness.dart';
import 'game_screen_test.dart' show quickScore, typeTotal;

final dialog = find.byKey(const Key('double-darts-dialog'));

Future<void> answer(WidgetTester tester, int count) async {
  await tester.tap(find.descendant(of: dialog, matching: find.text('$count')));
  await tester.pumpAndSettle();
}

/// A game on 40, where every visit is thrown at a double.
Future<void> launchOn40(WidgetTester tester, {required bool tracking}) async {
  await pumpApp(tester, await AppStorage.withTwoPlayers());
  await tester.tap(find.text('Nouvelle session'));
  await tester.pumpAndSettle();
  for (final name in ['Joueur 1', 'Joueur 2']) {
    await tester.tap(find.widgetWithText(CheckboxListTile, name));
    await tester.pump();
  }
  await tapInSetup(tester, 'Autre score…');
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('start-score-field')), '40');
  await tester.tap(find.text('Valider'));
  await tester.pumpAndSettle();
  if (tracking) await tapInSetup(tester, 'Pourcentage de checkout');
  await tester.tap(find.text('Lancer la partie'));
  await tester.pumpAndSettle();
  await switchToTotals(tester);
}

void main() {
  testWidgets('near a double, a total is asked its darts at a double', (
    tester,
  ) async {
    await launchOn40(tester, tracking: true);

    await tester.tap(find.text('0 / raté'));
    await tester.pumpAndSettle();
    expect(dialog, findsOneWidget);
    await answer(tester, 2);
    expect(
      tester.widget<Text>(find.byKey(const Key('active-name'))).data,
      'Joueur 2',
    );

    await quickScore(tester, 26);
    await tester.pumpAndSettle();
    await answer(tester, 0);

    // The checkout: how many darts, and one of them was at the double.
    await typeTotal(tester, 40);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '1').last);
    await tester.pumpAndSettle();
    expect(find.text('Joueur 1 gagne !'), findsOneWidget);

    await tester.tap(find.byKey(const Key('leave-game')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Statistiques'));
    await tester.pumpAndSettle();
    // Joueur 1: one checkout for three darts at a double.
    expect(find.text('33 % (1/3)'), findsOneWidget);
  });

  testWidgets('dismissing the question enters nothing', (tester) async {
    await launchOn40(tester, tracking: true);
    await tester.tap(find.text('0 / raté'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('active-name'))).data,
      'Joueur 1',
    );
  });

  testWidgets('without the option, nothing is asked', (tester) async {
    await launchOn40(tester, tracking: false);
    await tester.tap(find.text('0 / raté'));
    await tester.pumpAndSettle();

    expect(dialog, findsNothing);
    expect(
      tester.widget<Text>(find.byKey(const Key('active-name'))).data,
      'Joueur 2',
    );
  });
}
