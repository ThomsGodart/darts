import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_test_harness.dart';

void main() {
  testWidgets('a game left in progress is offered for resuming', (
    tester,
  ) async {
    final storage = await AppStorage.withTwoPlayers();
    await pumpApp(tester, storage);
    expect(find.text('Reprendre la partie'), findsNothing);

    await launchGame(tester);
    await tester.tap(find.widgetWithText(ActionChip, '60'));
    await tester.pump();

    // Relaunch the app on the same storage.
    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester, storage);

    await tester.tap(find.text('Reprendre la partie'));
    await tester.pumpAndSettle();
    expect(find.text('Joueur 2'), findsOneWidget);
    expect(find.text('441'), findsOneWidget);
  });
}
