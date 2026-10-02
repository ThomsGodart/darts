import 'package:darts_points_counter/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

String activeRemaining(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('active-remaining'))).data!;

Future<void> startGame(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const DartsApp());
  await tester.tap(find.text('Nouvelle partie 501'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a quick-score lowers the remaining and passes the turn', (
    tester,
  ) async {
    await startGame(tester);
    expect(activeRemaining(tester), '501');

    await tester.tap(find.widgetWithText(ActionChip, '60'));
    await tester.pump();

    // Joueur 2 is now up; Joueur 1 waits with 441.
    expect(find.text('Joueur 2'), findsOneWidget);
    expect(activeRemaining(tester), '501');
    expect(find.text('441'), findsOneWidget);
  });

  testWidgets('a typed total is submitted with OK', (tester) async {
    await startGame(tester);

    await tester.tap(find.widgetWithText(FilledButton, '4'));
    await tester.tap(find.widgetWithText(FilledButton, '5'));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('typed-total'))).data,
      '45',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'OK'));
    await tester.pump();
    expect(find.text('456'), findsOneWidget);
  });
}
