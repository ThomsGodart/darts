import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_test_harness.dart';
import 'game_screen_test.dart' show activeRemaining, playVisits;

/// Joueur 1 wins a 501 in nine darts (141 checks out in three by itself).
Future<void> joueur1Wins(WidgetTester tester) async {
  await playVisits(tester, [180, 26, 180, 26, 141]);
  await tester.pumpAndSettle();
  expect(find.text('Joueur 1 gagne !'), findsOneWidget);
}

void main() {
  testWidgets('the game-over panel; Rejouer starts a fresh game', (
    tester,
  ) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await launchGame(tester);
    await joueur1Wins(tester);
    expect(find.byKey(const Key('game-averages')), findsOneWidget);

    await tester.tap(find.text('Rejouer'));
    await tester.pumpAndSettle();

    expect(find.text('Joueur 1 gagne !'), findsNothing);
    expect(activeRemaining(tester), '501');
  });

  testWidgets('Changer… lets a late player join the next game', (tester) async {
    final storage = await AppStorage.withTwoPlayers();
    await pumpApp(tester, storage);
    await launchGame(tester);
    await joueur1Wins(tester);

    await tester.tap(find.text('Changer…'));
    await tester.pumpAndSettle();
    expect(find.text('Partie suivante'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Chloé');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lancer la partie'));
    await tester.pumpAndSettle();

    expect(find.text('Chloé'), findsOneWidget);
    expect(activeRemaining(tester), '501');
  });

  testWidgets('ending the soirée goes home with nothing to resume', (
    tester,
  ) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await launchGame(tester);
    await joueur1Wins(tester);

    await tester.tap(find.text('Terminer la soirée'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Terminer'));
    await tester.pumpAndSettle();

    expect(find.text('Nouvelle soirée'), findsOneWidget);
    expect(find.text('Reprendre la soirée'), findsNothing);
  });

  testWidgets('a finished game can be resumed to play again', (tester) async {
    final storage = await AppStorage.withTwoPlayers();
    await pumpApp(tester, storage);
    await launchGame(tester);
    await joueur1Wins(tester);

    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester, storage);
    await tester.tap(find.text('Reprendre la soirée'));
    await tester.pumpAndSettle();

    expect(find.text('Rejouer'), findsOneWidget);
  });

  testWidgets('a new soirée over an open one asks first, then ends it', (
    tester,
  ) async {
    final storage = await AppStorage.withTwoPlayers();
    await pumpApp(tester, storage);
    await launchGame(tester);
    await tester.tap(find.widgetWithText(ActionChip, '60'));
    await tester.pump();
    // Leave the game mid-way with the system back gesture.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nouvelle soirée'));
    await tester.pumpAndSettle();
    expect(find.text('Une soirée est en cours'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Reprendre la soirée'), findsOneWidget);

    await launchGameAfterConfirm(tester);
    expect(activeRemaining(tester), '501');
  });
}

Future<void> launchGameAfterConfirm(WidgetTester tester) async {
  await tester.tap(find.text('Nouvelle soirée'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Terminer et commencer'));
  await tester.pumpAndSettle();
  for (final name in ['Joueur 1', 'Joueur 2']) {
    await tester.tap(find.widgetWithText(CheckboxListTile, name));
    await tester.pump();
  }
  await tester.tap(find.text('Lancer la partie'));
  await tester.pumpAndSettle();
}
