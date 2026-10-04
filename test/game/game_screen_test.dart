import 'package:darts_points_counter/game/visit_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_test_harness.dart';

String activeRemaining(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('active-remaining'))).data!;

Future<void> startGame(WidgetTester tester) async {
  await pumpApp(tester, await AppStorage.withTwoPlayers());
  await launchGame(tester);
}

Future<void> quickScore(WidgetTester tester, int score) async {
  await tester.tap(find.widgetWithText(FilledButton, '$score'));
  await tester.pump();
}

/// Enters [scores] as visits, quick-scores when available.
Future<void> playVisits(WidgetTester tester, List<int> scores) async {
  for (final score in scores) {
    if (quickScores.contains(score)) {
      await quickScore(tester, score);
    } else {
      await typeTotal(tester, score);
    }
  }
}

Future<void> typeTotal(WidgetTester tester, int score) async {
  for (final digit in '$score'.split('')) {
    await tester.tap(find.widgetWithText(FilledButton, digit));
    // OK is only enabled once a digit has been rendered.
    await tester.pump();
  }
  await tester.tap(find.widgetWithText(FilledButton, 'OK'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a quick-score lowers the remaining and passes the turn', (
    tester,
  ) async {
    await startGame(tester);
    expect(activeRemaining(tester), '501');

    await tester.tap(find.widgetWithText(FilledButton, '60'));
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

  testWidgets('a checkout asks for the dart count, then names the winner', (
    tester,
  ) async {
    await startGame(tester);
    // Joueur 1 down to 40; Joueur 2 scores 26s.
    await playVisits(tester, [180, 26, 180, 26, 101, 26]);

    await typeTotal(tester, 40);
    expect(find.text('Combien de fléchettes ?'), findsOneWidget);
    final inDialog = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(FilledButton),
    );
    expect(inDialog, findsNWidgets(3));

    await tester.tap(find.descendant(of: inDialog, matching: find.text('2')));
    await tester.pumpAndSettle();
    expect(find.text('Joueur 1 gagne !'), findsOneWidget);
  });

  testWidgets('a checkout with a single possible dart count needs no dialog', (
    tester,
  ) async {
    await startGame(tester);
    await playVisits(tester, [180, 26, 180, 26]);

    // 141 double-out can only be done in three darts.
    await typeTotal(tester, 141);
    expect(find.text('Combien de fléchettes ?'), findsNothing);
    expect(find.text('Joueur 1 gagne !'), findsOneWidget);
  });

  testWidgets('a bust is flagged on the player who busted', (tester) async {
    await startGame(tester);
    await playVisits(tester, [180, 26, 180, 26]);

    await typeTotal(tester, 160);
    expect(find.textContaining('BUST'), findsOneWidget);
    expect(find.text('141'), findsOneWidget);
  });

  testWidgets('undo takes back visits, even the checkout', (tester) async {
    await startGame(tester);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Annuler la saisie'),
          )
          .onPressed,
      isNull,
    );

    await playVisits(tester, [180, 26, 180, 26, 141]);
    expect(find.text('Joueur 1 gagne !'), findsOneWidget);

    await tester.tap(find.text('Annuler le checkout'));
    await tester.pump();
    expect(find.text('Joueur 1 gagne !'), findsNothing);
    expect(activeRemaining(tester), '141');

    await tester.tap(find.text('Annuler la saisie'));
    await tester.pump();
    expect(find.text('Joueur 2'), findsOneWidget);
    // Joueur 2's second 26 is taken back: back to 501 - 26.
    expect(activeRemaining(tester), '475');
  });

  testWidgets('X01 opens dart by dart', (tester) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await launchGame(
      tester,
      const ['Joueur 1', 'Joueur 2'],
      null,
      const [],
      false,
    );

    expect(find.byKey(const Key('darts-in-visit')), findsOneWidget);
    expect(find.text('Triple'), findsOneWidget);
    // No quick-scores until the players ask for totals.
    expect(find.widgetWithText(FilledButton, '60'), findsNothing);

    await tester.tap(find.text('Triple'));
    await tester.pump();
    await tester.tap(find.text('T20'));
    await tester.pump();
    expect(activeRemaining(tester), '441');
  });

  testWidgets('the players’ choice of totals sticks for the visits after', (
    tester,
  ) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await launchGame(
      tester,
      const ['Joueur 1', 'Joueur 2'],
      null,
      const [],
      false,
    );

    await tester.tap(find.text('Total'));
    await tester.pump();
    await quickScore(tester, 60);
    await tester.pumpAndSettle();

    // The next visit opens on the totals too.
    expect(find.widgetWithText(FilledButton, '60'), findsOneWidget);
    expect(find.byKey(const Key('darts-in-visit')), findsNothing);
  });

  testWidgets('a visit entered dart by dart, and the next one too', (
    tester,
  ) async {
    await startGame(tester);

    await tester.tap(find.text('Fléchettes'));
    await tester.pump();
    await tester.tap(find.text('Triple'));
    await tester.pump();
    await tester.tap(find.text('T20'));
    await tester.pump();

    final darts = find.byKey(const Key('darts-in-visit'));
    expect(tester.widget<Text>(darts).data, startsWith('T20'));
    expect(activeRemaining(tester), '441');

    // Back to single after each dart.
    await tester.tap(find.text('5'));
    await tester.tap(find.text('Bull'));
    await tester.pump();

    expect(find.text('Joueur 2'), findsOneWidget);
    expect(find.text('386'), findsOneWidget);
    // Chosen once, darts stay the way visits open.
    expect(find.byKey(const Key('darts-in-visit')), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '60'), findsNothing);
  });

  testWidgets('a dart-by-dart visit cannot switch back to total', (
    tester,
  ) async {
    await startGame(tester);
    await tester.tap(find.text('Fléchettes'));
    await tester.pump();
    await tester.tap(find.text('20'));
    await tester.pump();

    await tester.tap(find.text('Total'));
    await tester.pump();
    expect(find.byKey(const Key('darts-in-visit')), findsOneWidget);
  });

  testWidgets('a checkout route shows once the remaining is in reach', (
    tester,
  ) async {
    await startGame(tester);
    final suggestion = find.byKey(const Key('checkout-suggestion'));
    expect(suggestion, findsNothing);

    await playVisits(tester, [180, 26, 180, 26]);
    // Which route is the rules tests' business; here, that one shows.
    expect(suggestion, findsOneWidget);
  });

  testWidgets('a bust from the last round is not shown on the next turn', (
    tester,
  ) async {
    await startGame(tester);
    await playVisits(tester, [180, 26, 180, 26]);
    await typeTotal(tester, 160); // Joueur 1 busts on 141
    expect(find.textContaining('BUST'), findsOneWidget);

    await quickScore(tester, 60); // Joueur 2 scores normally

    // Joueur 1 is up again: their old bust must not look like a new one.
    expect(find.textContaining('BUST'), findsNothing);
  });

  testWidgets('a dart-by-dart visit can end before its third dart', (
    tester,
  ) async {
    await startGame(tester);
    await tester.tap(find.text('Fléchettes'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '20'));
    await tester.pump();
    await tester.tap(find.text('Fin de tour'));
    await tester.pump();

    expect(
      tester.widget<Text>(find.byKey(const Key('active-name'))).data,
      'Joueur 2',
    );
    await tester.pumpAndSettle();
  });

  group('Back during a game', () {
    testWidgets('asks before cancelling what was played', (tester) async {
      await startGame(tester);
      await quickScore(tester, 60);
      await tester.tap(find.byKey(const Key('leave-game')));
      await tester.pumpAndSettle();

      expect(find.text('Annuler la partie ?'), findsOneWidget);
      await tester.tap(find.text('Continuer la partie'));
      await tester.pumpAndSettle();
      expect(activeRemaining(tester), '501');
      expect(find.text('441'), findsOneWidget);
    });

    testWidgets('once confirmed, reopens the setup as the game was set up', (
      tester,
    ) async {
      await startGame(tester);
      await quickScore(tester, 60);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Annuler la partie'));
      await tester.pumpAndSettle();

      // The setup: same players already picked.
      expect(find.text('Nouvelle partie'), findsOneWidget);
      await tester.tap(find.text('Lancer la partie'));
      await tester.pumpAndSettle();

      // A fresh game: the 60 is gone.
      expect(
        tester.widget<Text>(find.byKey(const Key('active-name'))).data,
        'Joueur 1',
      );
      expect(activeRemaining(tester), '501');
      expect(find.text('441'), findsNothing);
    });

    testWidgets('backing out of the setup too leads to the menu', (
      tester,
    ) async {
      await startGame(tester);
      await quickScore(tester, 60);
      await tester.tap(find.byKey(const Key('leave-game')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Annuler la partie'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Nouvelle session'), findsOneWidget);
      // The only game was cancelled: nothing is left to resume.
      expect(find.text('Reprendre la session'), findsNothing);
    });

    testWidgets('does not ask when nothing was played yet', (tester) async {
      await startGame(tester);
      await tester.tap(find.byKey(const Key('leave-game')));
      await tester.pumpAndSettle();

      expect(find.text('Annuler la partie ?'), findsNothing);
      expect(find.text('Nouvelle partie'), findsOneWidget);
    });

    testWidgets('between two games, leaves to the menu, the session kept', (
      tester,
    ) async {
      await startGame(tester);
      await playVisits(tester, [180, 26, 180, 26, 141]);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('leave-game')));
      await tester.pumpAndSettle();

      expect(find.text('Annuler la partie ?'), findsNothing);
      expect(find.text('Reprendre la session'), findsOneWidget);
    });
  });
}
