import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_test_harness.dart';
import 'landscape_screen_test.dart' show toLandscape;

const players = ['Joueur 1', 'Joueur 2'];

String titleOf(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('score-list-title'))).data!;

String hintOf(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('score-list-hint'))).data!;

Future<void> tapKey(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(FilledButton, label));
  await tester.pump();
}

void main() {
  group('Halve-It', () {
    testWidgets('hits show at once; a visit without one halves', (
      tester,
    ) async {
      await pumpApp(tester, await AppStorage.withTwoPlayers());
      await launchGame(tester, players, 'Halve-It');

      expect(titleOf(tester), 'Cible 20');
      await tapKey(tester, 'T20');
      expect(find.text('60'), findsOneWidget);

      await tester.tap(find.text('Fin de tour'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        await tapKey(tester, 'Raté');
      }
      await tester.tap(find.text('Fin de tour'));
      await tester.pumpAndSettle();

      expect(titleOf(tester), 'Cible 16');
      expect(find.text('÷2  0'), findsOneWidget);
    });

    testWidgets('only the ring that counts is offered', (tester) async {
      await pumpApp(tester, await AppStorage.withTwoPlayers());
      await launchGame(tester, players, 'Halve-It');
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('Fin de tour'));
        await tester.pumpAndSettle();
      }

      expect(titleOf(tester), 'Cible D7');
      expect(find.widgetWithText(FilledButton, 'D7'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'S7'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'T7'), findsNothing);
    });

    testWidgets('fits in landscape', (tester) async {
      await pumpApp(tester, await AppStorage.withTwoPlayers());
      await launchGame(tester, players, 'Halve-It');
      await toLandscape(tester);
      expect(find.byKey(const Key('halve-it-board')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Golf', () {
    testWidgets('stopping keeps the last dart thrown', (tester) async {
      await pumpApp(tester, await AppStorage.withTwoPlayers());
      await launchGame(tester, players, 'Golf');

      expect(titleOf(tester), 'Trou 1 / 9');
      await tapKey(tester, 'S1');
      expect(hintOf(tester), 'S’arrêter maintenant : 4 coups');
      await tapKey(tester, 'D1');
      expect(hintOf(tester), 'S’arrêter maintenant : 1 coup');

      await tester.tap(find.text('Fin de tour'));
      await tester.pump();
      expect(find.text('À toi, Joueur 2 !'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('eighteen holes can be chosen; the game ends on a winner', (
      tester,
    ) async {
      await pumpApp(tester, await AppStorage.withTwoPlayers());
      await launchGame(tester, const ['Joueur 1'], 'Golf', const ['18 trous']);

      expect(titleOf(tester), 'Trou 1 / 18');
      for (var hole = 0; hole < 18; hole++) {
        await tester.tap(find.text('Fin de tour'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Joueur 1 gagne !'), findsOneWidget);
      expect(find.text('coups'), findsOneWidget);
      expect(find.text('90'), findsWidgets);
    });

    testWidgets('fits in landscape', (tester) async {
      await pumpApp(tester, await AppStorage.withTwoPlayers());
      await launchGame(tester, players, 'Golf');
      await toLandscape(tester);
      expect(find.byKey(const Key('golf-board')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
