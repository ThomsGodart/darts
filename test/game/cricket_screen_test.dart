import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_test_harness.dart';
import 'session_flow_test.dart' show joueur1Wins;

Future<void> launchCricket(WidgetTester tester) async {
  await pumpApp(tester, await AppStorage.withTwoPlayers());
  await launchGame(tester, const ['Joueur 1', 'Joueur 2'], 'Cricket');
}

void main() {
  testWidgets('a cricket game shows the board and darts only', (tester) async {
    await launchCricket(tester);

    expect(find.byKey(const Key('cricket-board')), findsOneWidget);
    expect(find.text('Bull'), findsWidgets);
    // No totals in cricket: no quick-scores, no Total / Fléchettes switch.
    expect(find.byType(ActionChip), findsNothing);
    expect(find.text('Total'), findsNothing);
    expect(find.byKey(const Key('darts-in-visit')), findsOneWidget);
  });

  testWidgets('a dart marks the board', (tester) async {
    await launchCricket(tester);
    await tester.tap(find.text('Triple'));
    await tester.pump();
    await tester.tap(find.text('T20'));
    await tester.pump();

    // Which mark is the rules' business; here, one shows up on the board.
    final board = find.byKey(const Key('cricket-board'));
    final marks = find.descendant(
      of: board,
      matching: find.byWidgetPredicate(
        (w) => w is Text && ['/', 'X', 'Ⓧ'].contains(w.data),
      ),
    );
    expect(marks, findsOneWidget);
  });

  testWidgets('cut-throat is chosen in the setup and shown in game', (
    tester,
  ) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await tester.tap(find.text('Nouvelle session'));
    await tester.pumpAndSettle();
    for (final name in ['Joueur 1', 'Joueur 2']) {
      await tester.tap(find.widgetWithText(CheckboxListTile, name));
      await tester.pump();
    }
    await tester.ensureVisible(find.text('Cricket'));
    await tester.tap(find.text('Cricket'));
    await tester.pump();
    await tester.ensureVisible(find.text('Cut-Throat'));
    await tester.tap(find.text('Cut-Throat'));
    await tester.pump();
    await tester.tap(find.text('Lancer la partie'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('cricket-variant'))).data,
      startsWith('Cut-Throat'),
    );
  });

  testWidgets('Changer… switches from X01 to cricket mid-session', (
    tester,
  ) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await launchGame(tester);
    await joueur1Wins(tester);

    await tester.tap(find.text('Changer…'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Cricket'));
    await tester.tap(find.text('Cricket'));
    await tester.pump();
    await tester.tap(find.text('Lancer la partie'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cricket-board')), findsOneWidget);
    expect(find.text('MPR'), findsOneWidget);
  });
}
