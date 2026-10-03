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
    await tester.tap(find.text('Nouvelle soirée'));
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
    await tester.tap(find.text('301'));
    await tester.pump();
    await tester.tap(find.text('Lancer la partie'));
    await tester.pumpAndSettle();

    // Added players are picked in the order they were added.
    expect(find.text('Ana'), findsOneWidget);
    expect(activeRemaining(tester), '301');
  });

  testWidgets('a taken name is refused inline', (tester) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await tester.tap(find.text('Nouvelle soirée'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'joueur 1');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Ce nom est déjà pris'), findsOneWidget);
  });

  testWidgets('players are known again on the next soirée', (tester) async {
    final storage = AppStorage();
    await pumpApp(tester, storage);
    await tester.tap(find.text('Nouvelle soirée'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Ana');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nouvelle soirée'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(CheckboxListTile, 'Ana'), findsOneWidget);
  });
}
