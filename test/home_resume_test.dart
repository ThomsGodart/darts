import 'package:darts_points_counter/app.dart';
import 'package:darts_points_counter/soiree/soiree.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a game left in progress is offered for resuming', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final storage = InMemorySoireeStorage();

    await tester.pumpWidget(
      DartsApp(repository: InMemorySoireeRepository(storage)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Reprendre la partie'), findsNothing);

    await tester.tap(find.text('Nouvelle partie 501'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ActionChip, '60'));
    await tester.pump();

    // Relaunch the app on the same storage.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      DartsApp(repository: InMemorySoireeRepository(storage)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reprendre la partie'));
    await tester.pumpAndSettle();
    expect(find.text('Joueur 2'), findsOneWidget);
    expect(find.text('441'), findsOneWidget);
  });
}
