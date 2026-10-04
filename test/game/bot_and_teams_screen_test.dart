import 'package:darts_points_counter/session/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_test_harness.dart';
import 'game_screen_test.dart' show activeRemaining, quickScore;

String activeName(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('active-name'))).data!;

Future<AppStorage> fourPlayers() async {
  final storage = AppStorage();
  final catalog = InMemoryPlayerCatalog(storage.players);
  for (var i = 1; i <= 4; i++) {
    await catalog.add('Joueur $i');
  }
  return storage;
}

void main() {
  group('virtual opponent', () {
    Future<void> launchAgainstBot(WidgetTester tester) async {
      await pumpApp(tester, await AppStorage.withTwoPlayers());
      await tester.tap(find.text('Nouvelle session'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Joueur 1'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('add-bot')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Moyenne 60'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lancer la partie'));
      await tester.pumpAndSettle();
    }

    testWidgets('it throws by itself, then hands the phone back', (
      tester,
    ) async {
      await launchAgainstBot(tester);
      expect(activeName(tester), 'Joueur 1');

      await quickScore(tester, 60);
      expect(activeName(tester), 'Bot 60');
      expect(find.byKey(const Key('bot-playing')), findsOneWidget);
      // No keys while it throws.
      expect(find.widgetWithText(FilledButton, '60'), findsNothing);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(activeName(tester), 'Joueur 1');
      expect(activeRemaining(tester), '441');
      expect(find.byKey(const Key('bot-playing')), findsNothing);
    });

    testWidgets('undo takes its visit back with the player’s', (tester) async {
      await launchAgainstBot(tester);
      await quickScore(tester, 60);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Annuler la saisie'));
      await tester.pumpAndSettle();

      expect(activeName(tester), 'Joueur 1');
      expect(activeRemaining(tester), '501');
      // Nothing is left pending: the bot does not throw again.
      await tester.pump(const Duration(seconds: 2));
      expect(activeName(tester), 'Joueur 1');
    });

    testWidgets('it cannot join a game entered dart by dart', (tester) async {
      await pumpApp(tester, await AppStorage.withTwoPlayers());
      await tester.tap(find.text('Nouvelle session'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Joueur 1'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('add-bot')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Moyenne 40'));
      await tester.pumpAndSettle();
      await tapInSetup(tester, 'Cricket');

      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Lancer la partie'),
            )
            .onPressed,
        isNull,
      );
    });
  });

  group('teams', () {
    testWidgets('pairs share a score and take turns to throw', (tester) async {
      await pumpApp(tester, await fourPlayers());
      await tester.tap(find.text('Nouvelle session'));
      await tester.pumpAndSettle();
      for (var i = 1; i <= 4; i++) {
        await tester.tap(find.widgetWithText(CheckboxListTile, 'Joueur $i'));
        await tester.pump();
      }
      await tapInSetup(tester, 'Équipes de 2');
      expect(
        find.text('Joueur 1 & Joueur 2  ·  Joueur 3 & Joueur 4'),
        findsOneWidget,
      );
      await tester.tap(find.text('Lancer la partie'));
      await tester.pumpAndSettle();

      expect(activeName(tester), 'Joueur 1 & Joueur 2');
      expect(find.textContaining('Joueur 1 lance'), findsOneWidget);

      await quickScore(tester, 60);
      expect(find.text('À toi, Joueur 3 !'), findsOneWidget);
      await tester.pumpAndSettle();
      await quickScore(tester, 45);
      expect(find.text('À toi, Joueur 2 !'), findsOneWidget);
      await tester.pumpAndSettle();

      // One score for the pair.
      expect(activeName(tester), 'Joueur 1 & Joueur 2');
      expect(activeRemaining(tester), '441');
    });

    testWidgets('an odd number of players cannot make teams', (tester) async {
      await pumpApp(tester, await fourPlayers());
      await tester.tap(find.text('Nouvelle session'));
      await tester.pumpAndSettle();
      for (var i = 1; i <= 3; i++) {
        await tester.tap(find.widgetWithText(CheckboxListTile, 'Joueur $i'));
        await tester.pump();
      }
      await tapInSetup(tester, 'Équipes de 2');
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('setup-problem')), findsOneWidget);
    });
  });
}
