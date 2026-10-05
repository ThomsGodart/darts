import 'package:darts_points_counter/session/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_test_harness.dart';
import 'game_screen_test.dart' show activeRemaining, playVisits, quickScore;

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
      await switchToTotals(tester);
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

      await tester.tap(find.byKey(const Key('undo')));
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
    Future<void> pickPlayers(WidgetTester tester, int count) async {
      await tester.tap(find.text('Nouvelle session'));
      await tester.pumpAndSettle();
      for (var i = 1; i <= count; i++) {
        await tester.tap(find.widgetWithText(CheckboxListTile, 'Joueur $i'));
        await tester.pump();
      }
    }

    String summary(WidgetTester tester) =>
        tester.widget<Text>(find.byKey(const Key('teams-summary'))).data!;

    testWidgets('two players are not offered teams; three are', (tester) async {
      await pumpApp(tester, await fourPlayers());
      await pickPlayers(tester, 2);
      final setup = find.byType(Scrollable).first;
      // The whole setup, down to its last rule: no teams anywhere.
      await tester.drag(setup, const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('team-count')), findsNothing);
      expect(find.text('Équipes'), findsNothing);

      await tester.drag(setup, const Offset(0, 3000));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Joueur 3'));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.byKey(const Key('team-count')),
        100,
        scrollable: setup,
      );
      expect(find.byKey(const Key('team-count')), findsOneWidget);
    });

    testWidgets('a team of several wins in the plural', (tester) async {
      await pumpApp(tester, await fourPlayers());
      await pickPlayers(tester, 4);
      await tapInSetup(tester, '2 équipes');
      await tester.tap(find.text('Lancer la partie'));
      await tester.pumpAndSettle();
      await switchToTotals(tester);

      await playVisits(tester, [180, 26, 180, 26, 141]);
      await tester.pumpAndSettle();
      expect(find.text('Joueur 1 & Joueur 3 gagnent !'), findsOneWidget);
    });

    testWidgets('a team shares a score; a banner says whose throw it is', (
      tester,
    ) async {
      await pumpApp(tester, await fourPlayers());
      await pickPlayers(tester, 4);
      await tapInSetup(tester, '2 équipes');
      expect(
        summary(tester),
        'Équipe 1 : Joueur 1 & Joueur 3\nÉquipe 2 : Joueur 2 & Joueur 4',
      );
      await tester.tap(find.text('Lancer la partie'));
      await tester.pumpAndSettle();
      await switchToTotals(tester);

      final banner = find.byKey(const Key('thrower-banner'));
      // The team is named in the banner, once: its block is its score.
      expect(
        find.descendant(
          of: banner,
          matching: find.text('Équipe Joueur 1 & Joueur 3'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('active-name')), findsNothing);
      expect(find.byKey(const Key('active-summary')), findsNothing);
      expect(
        find.descendant(of: banner, matching: find.text('Joueur 1 lance')),
        findsOneWidget,
      );

      await quickScore(tester, 60);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: banner, matching: find.text('Joueur 2 lance')),
        findsOneWidget,
      );
      await quickScore(tester, 45);
      await tester.pumpAndSettle();

      // Back to the first team: its other member, on the shared score.
      expect(
        find.descendant(of: banner, matching: find.text('Joueur 3 lance')),
        findsOneWidget,
      );
      expect(activeRemaining(tester), '441');
    });

    testWidgets('players choose their team: three against one', (tester) async {
      await pumpApp(tester, await fourPlayers());
      await pickPlayers(tester, 4);
      await tapInSetup(tester, '2 équipes');

      // Joueur 2 joins team 1, leaving Joueur 4 alone in team 2.
      final team = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('team-of-'),
      );
      await tester.ensureVisible(team.at(1));
      await tester.tap(
        find.descendant(of: team.at(1), matching: find.text('1')),
      );
      await tester.pumpAndSettle();

      expect(
        summary(tester),
        'Équipe 1 : Joueur 1 & Joueur 2 & Joueur 3\nÉquipe 2 : Joueur 4',
      );
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Lancer la partie'),
            )
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('no banner when everyone plays for themselves', (tester) async {
      await pumpApp(tester, await fourPlayers());
      await pickPlayers(tester, 2);
      await tester.tap(find.text('Lancer la partie'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('thrower-banner')), findsNothing);
    });

    testWidgets('a bot in a team throws on its turn, for the shared score', (
      tester,
    ) async {
      await pumpApp(tester, await AppStorage.withTwoPlayers());
      await pickPlayers(tester, 2);
      for (final level in ['Moyenne 60', 'Moyenne 40']) {
        await tester.tap(find.byKey(const Key('add-bot')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(level));
        await tester.pumpAndSettle();
      }
      await tapInSetup(tester, '2 équipes');
      expect(
        summary(tester),
        'Équipe 1 : Joueur 1 & Bot 60\nÉquipe 2 : Joueur 2 & Bot 40',
      );
      expect(find.byKey(const Key('setup-problem')), findsNothing);
      await tester.tap(find.text('Lancer la partie'));
      await tester.pumpAndSettle();
      await switchToTotals(tester);

      final banner = find.byKey(const Key('thrower-banner'));
      await quickScore(tester, 60); // Joueur 1
      await tester.pumpAndSettle();
      await quickScore(tester, 45); // Joueur 2
      // Not settling: the bot would have thrown by then.
      await tester.pump();

      // Bot 60 is up for the first team: it throws by itself.
      expect(
        find.descendant(of: banner, matching: find.text('Bot 60 lance')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('bot-playing')), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      // Then Bot 40 for the second, and the phone is back with Joueur 1.
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: banner, matching: find.text('Joueur 1 lance')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('bot-playing')), findsNothing);
    });
  });
}
