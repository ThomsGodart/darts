import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_test_harness.dart';

String activeRemaining(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('active-remaining'))).data!;

void main() {
  testWidgets('first launch: add players inline, choose 301, play', (
    tester,
  ) async {
    await pumpApp(tester, AppStorage());
    await tester.tap(find.text('Nouvelle session'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Lancer la partie'),
          )
          .onPressed,
      isNull,
    );

    for (final name in ['Ana', 'Bob']) {
      await tester.enterText(find.byType(TextField), name);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    }
    await tapInSetup(tester, '301');
    await tester.tap(find.text('Lancer la partie'));
    await tester.pumpAndSettle();

    // Added players are picked in the order they were added.
    expect(find.text('Ana'), findsOneWidget);
    expect(activeRemaining(tester), '301');
  });

  testWidgets('a taken name is refused inline', (tester) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await tester.tap(find.text('Nouvelle session'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'joueur 1');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Ce nom est déjà pris'), findsOneWidget);
  });

  testWidgets('players are known again on the next session', (tester) async {
    final storage = AppStorage();
    await pumpApp(tester, storage);
    await tester.tap(find.text('Nouvelle session'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Ana');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nouvelle session'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(CheckboxListTile, 'Ana'), findsOneWidget);
  });

  testWidgets('deleting a player asks first', (tester) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await tester.tap(find.text('Nouvelle session'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Options de Joueur 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer Joueur 1 ?'), findsOneWidget);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(CheckboxListTile, 'Joueur 1'), findsOneWidget);

    await tester.tap(find.byTooltip('Options de Joueur 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(CheckboxListTile, 'Joueur 1'), findsNothing);
  });

  testWidgets('only a game needing several players says so', (tester) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await tester.tap(find.text('Nouvelle session'));
    await tester.pumpAndSettle();

    Future<void> scrollToEnd() async {
      // More than one fling: the rules under the games keep growing.
      for (var i = 0; i < 3; i++) {
        await tester.drag(
          find.byType(Scrollable).first,
          const Offset(0, -2000),
        );
        await tester.pumpAndSettle();
      }
    }

    for (final game in ['X01', 'Cricket', 'Shanghai']) {
      await tapInSetup(tester, game);
      await scrollToEnd();
      expect(find.textContaining('au moins'), findsNothing, reason: game);
    }
    await tapInSetup(tester, 'Killer');
    await scrollToEnd();
    expect(find.text('Killer : au moins 3 joueurs'), findsOneWidget);
  });

  testWidgets('X01: a typed start score, master-out and double-in', (
    tester,
  ) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await tester.tap(find.text('Nouvelle session'));
    await tester.pumpAndSettle();
    for (final name in ['Joueur 1', 'Joueur 2']) {
      await tester.tap(find.widgetWithText(CheckboxListTile, name));
      await tester.pump();
    }

    await tapInSetup(tester, 'Autre score…');
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('start-score-field')), '1001');
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    expect(find.text('Score de départ : 1001'), findsOneWidget);

    await tapInSetup(tester, 'Master-out');
    await tapInSetup(tester, 'Double-in');
    await tester.tap(find.text('Lancer la partie'));
    await tester.pumpAndSettle();

    expect(activeRemaining(tester), '1001');
    expect(find.text('1001 Double-in Master-out'), findsOneWidget);
  });

  testWidgets('X01: a start score that cannot be played is ignored', (
    tester,
  ) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await tester.tap(find.text('Nouvelle session'));
    await tester.pumpAndSettle();

    await tapInSetup(tester, 'Autre score…');
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('start-score-field')), '1');
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    expect(find.text('Autre score…'), findsOneWidget);
  });

  testWidgets('the throwing order shows it can be dragged, and is', (
    tester,
  ) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await tester.tap(find.text('Nouvelle session'));
    await tester.pumpAndSettle();
    for (final name in ['Joueur 1', 'Joueur 2']) {
      await tester.tap(find.widgetWithText(CheckboxListTile, name));
      await tester.pump();
    }

    expect(find.byKey(const Key('reorder-hint')), findsOneWidget);
    expect(find.byIcon(Icons.drag_handle), findsNWidgets(2));

    // Drag the first handle below the second player: no long press.
    final handle = find.byIcon(Icons.drag_handle).first;
    await tester.ensureVisible(handle);
    await tester.pumpAndSettle();
    await tester.timedDrag(
      handle,
      const Offset(0, 140),
      const Duration(milliseconds: 800),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lancer la partie'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('active-name'))).data,
      'Joueur 2',
    );
  });

  testWidgets('holding a row of the throwing order moves it too', (
    tester,
  ) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await tester.tap(find.text('Nouvelle session'));
    await tester.pumpAndSettle();
    for (final name in ['Joueur 1', 'Joueur 2']) {
      await tester.tap(find.widgetWithText(CheckboxListTile, name));
      await tester.pump();
    }

    // The name in the order list, not its checkbox above.
    final row = find.descendant(
      of: find.byType(ReorderableListView),
      matching: find.text('Joueur 1'),
    );
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(tester.getCenter(row));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    for (var step = 0; step < 7; step++) {
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lancer la partie'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('active-name'))).data,
      'Joueur 2',
    );
  });
}
