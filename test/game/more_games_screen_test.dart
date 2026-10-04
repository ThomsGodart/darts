import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_test_harness.dart';
import 'landscape_screen_test.dart' show toLandscape;

const players = ['Joueur 1', 'Joueur 2'];

String titleOf(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('score-list-title'))).data!;

Future<void> tapKey(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(FilledButton, label));
  await tester.pump();
}

Future<void> endVisit(WidgetTester tester) async {
  await tester.tap(find.text('Fin de tour'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Around the Clock: the key follows the number to hit', (
    tester,
  ) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await launchGame(tester, players, 'Tour de l’horloge');

    expect(titleOf(tester), 'Cible 1');
    await tapKey(tester, '1');
    expect(titleOf(tester), 'Cible 2');
    await tapKey(tester, '2');
    expect(find.text('2 / 20'), findsOneWidget);

    await endVisit(tester);
    expect(titleOf(tester), 'Cible 1');
  });

  testWidgets("Bob's 27: a hit adds, a visit without one costs", (
    tester,
  ) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await launchGame(tester, players, 'Bob’s 27');

    expect(titleOf(tester), 'Cible D1');
    await tapKey(tester, 'D1');
    await endVisit(tester);
    await endVisit(tester);

    expect(titleOf(tester), 'Cible D2');
    expect(find.text('29'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
  });

  testWidgets('Count-Up: a visit is one tap on its total', (tester) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await launchGame(tester, players, 'Count-Up');

    expect(titleOf(tester), 'Manche 1 / 8');
    await tapKey(tester, '100');
    await tester.pumpAndSettle();
    expect(find.text('100'), findsWidgets);

    // Dart by dart works too, and shows the total as it grows.
    await tester.tap(find.text('Fléchettes'));
    await tester.pump();
    await tapKey(tester, '20');
    expect(
      find.descendant(
        of: find.byKey(const Key('count-up-board')),
        matching: find.text('20'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Baseball: runs on the number of the inning', (tester) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await launchGame(tester, players, 'Baseball');

    expect(titleOf(tester), 'Manche 1 / 9');
    await tapKey(tester, 'T1');
    await tapKey(tester, 'S1');
    expect(
      find.descendant(
        of: find.byKey(const Key('baseball-board')),
        matching: find.text('4'),
      ),
      findsOneWidget,
    );
  });

  for (final game in [
    'Tour de l’horloge',
    'Bob’s 27',
    'Count-Up',
    'Baseball',
  ]) {
    testWidgets('$game fits in landscape', (tester) async {
      await pumpApp(tester, await AppStorage.withTwoPlayers());
      await launchGame(tester, const ['Joueur 1'], game);
      await toLandscape(tester);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Around the Clock ends on a winner, not on a next target', (
    tester,
  ) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await launchGame(tester, const ['Joueur 1'], 'Tour de l’horloge');
    for (var n = 1; n <= 20; n++) {
      await tapKey(tester, '$n');
    }
    await tester.pumpAndSettle();

    expect(find.text('Joueur 1 gagne !'), findsOneWidget);
    expect(titleOf(tester), 'Tour bouclé');
    expect(find.text('20 / 20'), findsOneWidget);
  });

  testWidgets("Bob's 27 shows who is out, then the game over panel", (
    tester,
  ) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await launchGame(tester, const ['Joueur 1'], 'Bob’s 27');
    for (var n = 1; n <= 5; n++) {
      await endVisit(tester);
    }

    expect(find.text('OUT  -3'), findsOneWidget);
    expect(find.text('Joueur 1 gagne !'), findsOneWidget);
  });

  testWidgets('Count-Up and Baseball end on the game over panel', (
    tester,
  ) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await launchGame(tester, const ['Joueur 1'], 'Count-Up');
    for (var round = 0; round < 8; round++) {
      await tapKey(tester, '100');
      await tester.pumpAndSettle();
    }
    expect(find.text('Joueur 1 gagne !'), findsOneWidget);
    expect(find.text('800'), findsWidgets);

    await tester.tap(find.text('Partie suivante'));
    await tester.pumpAndSettle();
    await tapInSetup(tester, 'Baseball');
    await tester.tap(find.text('Lancer la partie'));
    await tester.pumpAndSettle();
    for (var inning = 0; inning < 9; inning++) {
      await endVisit(tester);
    }
    expect(find.text('Joueur 1 gagne !'), findsOneWidget);
    expect(find.text('runs'), findsOneWidget);
  });
}
