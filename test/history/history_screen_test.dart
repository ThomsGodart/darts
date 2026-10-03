import 'package:darts_points_counter/history/formatting.dart';
import 'package:darts_points_counter/soiree/soiree.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_test_harness.dart';

/// Stores an ended soirée where Joueur 1 beats Joueur 2 at 40 double-out.
Future<void> playedSoiree(AppStorage storage) async {
  final players = await InMemoryPlayerCatalog(storage.players).active();
  final soiree = await InMemorySoireeRepository(storage.soirees).create();
  soiree
    ..startGame(players, config: const X01Config(startScore: 40))
    ..submitVisitTotal(40, dartsAtCheckout: 1)
    ..endSoiree();
}

Future<void> openHistory(WidgetTester tester) async {
  await tester.tap(find.text('Historique'));
  await tester.pumpAndSettle();
}

void main() {
  test('dates read the French way', () {
    expect(soireeDate(DateTime(2026, 10, 3, 21, 5)), 'sam. 03/10/2026 · 21:05');
    expect(gamesCount(1), '1 partie');
    expect(gamesCount(3), '3 parties');
  });

  testWidgets('empty at first', (tester) async {
    await pumpApp(tester, AppStorage());
    await openHistory(tester);
    expect(find.text('Aucune soirée pour l’instant'), findsOneWidget);
  });

  testWidgets('lists a soirée, shows its detail', (tester) async {
    final storage = await AppStorage.withTwoPlayers();
    await playedSoiree(storage);
    await pumpApp(tester, storage);
    await openHistory(tester);

    expect(find.text('Joueur 1, Joueur 2 · 1 partie'), findsOneWidget);

    await tester.tap(find.text('Joueur 1, Joueur 2 · 1 partie'));
    await tester.pumpAndSettle();

    // Which winner and averages is the facade's business; here, they show.
    expect(find.text('Partie 1 · 40 DO'), findsOneWidget);
    expect(find.byKey(const Key('soiree-averages')), findsOneWidget);
  });

  testWidgets('the open soirée is not listed: it is resumed instead', (
    tester,
  ) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await launchGame(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await openHistory(tester);
    expect(find.text('Aucune soirée pour l’instant'), findsOneWidget);
  });

  testWidgets('a soirée can be deleted after confirming', (tester) async {
    final storage = await AppStorage.withTwoPlayers();
    await playedSoiree(storage);
    await pumpApp(tester, storage);
    await openHistory(tester);
    await tester.tap(find.text('Joueur 1, Joueur 2 · 1 partie'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Supprimer la soirée'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Partie 1 · 40 DO'), findsOneWidget);

    await tester.tap(find.byTooltip('Supprimer la soirée'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
    await tester.pumpAndSettle();

    expect(find.text('Aucune soirée pour l’instant'), findsOneWidget);
  });
}
