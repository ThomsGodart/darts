import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_test_harness.dart';
import 'session_flow_test.dart' show joueur1Wins;

Future<void> launchCricket(WidgetTester tester) async {
  await pumpApp(tester, await AppStorage.withTwoPlayers());
  await launchGame(tester, const ['Joueur 1', 'Joueur 2'], 'Cricket');
}

Finder boardMarks() => find.descendant(
  of: find.byKey(const Key('cricket-board')),
  matching: find.byWidgetPredicate(
    (w) => w is Text && ['/', 'X', 'Ⓧ'].contains(w.data),
  ),
);

void main() {
  testWidgets('a cricket game is entered on the board by default', (
    tester,
  ) async {
    await launchCricket(tester);

    expect(find.byKey(const Key('cricket-board')), findsOneWidget);
    // Single, double and treble sit between the two players' columns.
    final keys = tester.getCenter(find.byKey(const ValueKey('board-key-D20')));
    expect(tester.getCenter(find.text('Joueur 1')).dx, lessThan(keys.dx));
    expect(tester.getCenter(find.text('Joueur 2')).dx, greaterThan(keys.dx));
    // No keypad, and no totals in cricket.
    expect(find.text('Triple'), findsNothing);
    expect(find.text('Total'), findsNothing);
    expect(find.byKey(const Key('darts-in-visit')), findsOneWidget);
  });

  testWidgets('a dart tapped on the board marks it', (tester) async {
    await launchCricket(tester);
    await tester.tap(find.byKey(const ValueKey('board-key-T20')));
    await tester.pump();

    // Which mark is the rules' business; here, one shows up on the board.
    expect(boardMarks(), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('darts-in-visit'))).data,
      startsWith('T20'),
    );
  });

  testWidgets('Fin de tour passes the phone after a single dart', (
    tester,
  ) async {
    await launchCricket(tester);
    await tester.tap(find.byKey(const ValueKey('board-key-20')));
    await tester.pump();
    await tester.tap(find.text('Fin de tour'));
    await tester.pump();

    expect(find.text('À toi, Joueur 2 !'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('the dart keypad is chosen in the setup', (tester) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await launchGame(
      tester,
      const ['Joueur 1', 'Joueur 2'],
      'Cricket',
      const ['Clavier fléchettes'],
    );

    expect(find.byKey(const ValueKey('board-key-T20')), findsNothing);
    await tester.tap(find.text('Triple'));
    await tester.pump();
    await tester.tap(find.text('T20'));
    await tester.pump();
    expect(boardMarks(), findsOneWidget);

    // One dart in: the visit can still be ended.
    await tester.tap(find.text('Fin de tour'));
    await tester.pump();
    expect(find.text('À toi, Joueur 2 !'), findsOneWidget);
    await tester.pumpAndSettle();
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

  testWidgets('Partie suivante switches from X01 to cricket mid-session', (
    tester,
  ) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await launchGame(tester);
    await joueur1Wins(tester);

    await tester.tap(find.text('Partie suivante'));
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
