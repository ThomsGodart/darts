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
  testWidgets('a new session starts from the last players and game', (
    tester,
  ) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await launchGame(
      tester,
      const ['Joueur 2', 'Joueur 1'],
      'Cricket',
      const ['Cut-Throat'],
    );
    await tester.tap(find.byKey(const Key('leave-game')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nouvelle session'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terminer et commencer'));
    await tester.pumpAndSettle();
    // Nothing to pick again: same players, same order, same rules.
    await tester.tap(find.text('Lancer la partie'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('cricket-variant'))).data,
      startsWith('Cut-Throat'),
    );
    final board = find.byKey(const Key('cricket-board'));
    final names = [
      for (final name in ['Joueur 2', 'Joueur 1'])
        tester
            .getCenter(find.descendant(of: board, matching: find.text(name)))
            .dx,
    ];
    expect(names.first, lessThan(names.last));
  });

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

  testWidgets('Partie suivante lets a late player join the next game', (
    tester,
  ) async {
    final storage = await AppStorage.withTwoPlayers();
    await pumpApp(tester, storage);
    await launchGame(tester);
    await joueur1Wins(tester);

    await tester.tap(find.text('Partie suivante'));
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

  testWidgets('ending the session goes home with nothing to resume', (
    tester,
  ) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await launchGame(tester);
    await joueur1Wins(tester);

    await tester.tap(find.text('Terminer la session'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Terminer'));
    await tester.pumpAndSettle();

    expect(find.text('Nouvelle session'), findsOneWidget);
    expect(find.text('Reprendre la session'), findsNothing);
  });

  testWidgets('a finished game can be resumed to play again', (tester) async {
    final storage = await AppStorage.withTwoPlayers();
    await pumpApp(tester, storage);
    await launchGame(tester);
    await joueur1Wins(tester);

    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester, storage);
    await tester.tap(find.text('Reprendre la session'));
    await tester.pumpAndSettle();

    expect(find.text('Rejouer'), findsOneWidget);
  });

  testWidgets('a new session over an open one asks first, then ends it', (
    tester,
  ) async {
    final storage = await AppStorage.withTwoPlayers();
    await pumpApp(tester, storage);
    await launchGame(tester);
    await tester.tap(find.widgetWithText(FilledButton, '60'));
    await tester.pump();
    // Leave the game mid-way with the system back gesture.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nouvelle session'));
    await tester.pumpAndSettle();
    expect(find.text('Une session est en cours'), findsOneWidget);
    // The open session only ends once the new game actually starts.
    expect(
      find.textContaining('au lancement de la nouvelle partie'),
      findsOneWidget,
    );
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Reprendre la session'), findsOneWidget);

    await launchGameAfterConfirm(tester);
    expect(activeRemaining(tester), '501');
  });
}

Future<void> launchGameAfterConfirm(WidgetTester tester) async {
  await tester.tap(find.text('Nouvelle session'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Terminer et commencer'));
  await tester.pumpAndSettle();
  // The players of the session being ended are picked already.
  await tester.tap(find.text('Lancer la partie'));
  await tester.pumpAndSettle();
}
