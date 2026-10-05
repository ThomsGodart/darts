import 'package:darts_points_counter/history/formatting.dart';
import 'package:darts_points_counter/session/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_test_harness.dart';

/// Stores an ended session where Joueur 1 beats Joueur 2 at 40 double-out.
Future<void> playedSession(AppStorage storage) async {
  final players = await InMemoryPlayerCatalog(storage.players).active();
  final session = await InMemorySessionRepository(storage.sessions).create();
  session
    ..startGame(players, config: const X01Config(startScore: 40))
    ..submitVisitTotal(40, dartsAtCheckout: 1)
    ..endSession();
}

Future<void> openHistory(WidgetTester tester) async {
  await tester.tap(find.text('Historique'));
  await tester.pumpAndSettle();
}

void main() {
  test('dates read the French way', () {
    expect(
      sessionDate(DateTime(2026, 10, 3, 21, 5)),
      'sam. 03/10/2026 · 21:05',
    );
    expect(gamesCount(1), '1 partie');
    expect(gamesCount(3), '3 parties');
  });

  testWidgets('empty at first', (tester) async {
    await pumpApp(tester, AppStorage());
    await openHistory(tester);
    expect(find.text('Aucune session pour l’instant'), findsOneWidget);
  });

  testWidgets('lists a session, shows its detail', (tester) async {
    final storage = await AppStorage.withTwoPlayers();
    await playedSession(storage);
    await pumpApp(tester, storage);
    await openHistory(tester);

    expect(find.text('Joueur 1, Joueur 2 · 1 partie'), findsOneWidget);

    await tester.tap(find.text('Joueur 1, Joueur 2 · 1 partie'));
    await tester.pumpAndSettle();

    // Which winner and averages is the facade's business; here, they show.
    expect(find.text('Partie 1 · 40 Double-out'), findsOneWidget);
    expect(find.byKey(const Key('session-stats')), findsOneWidget);
  });

  testWidgets('a long press deletes a session, once confirmed', (tester) async {
    final storage = await AppStorage.withTwoPlayers();
    await playedSession(storage);
    await pumpApp(tester, storage);
    await openHistory(tester);

    await tester.longPress(find.text('Joueur 1, Joueur 2 · 1 partie'));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer cette session ?'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Joueur 1, Joueur 2 · 1 partie'), findsOneWidget);

    await tester.longPress(find.text('Joueur 1, Joueur 2 · 1 partie'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    expect(find.text('Aucune session pour l’instant'), findsOneWidget);
  });

  testWidgets('Tout effacer empties the history and the stats, not the '
      'open session', (tester) async {
    final storage = await AppStorage.withTwoPlayers();
    await playedSession(storage);
    await playedSession(storage);
    final players = await InMemoryPlayerCatalog(storage.players).active();
    (await InMemorySessionRepository(
      storage.sessions,
    ).create()).startGame(players);
    await pumpApp(tester, storage);
    await openHistory(tester);

    await tester.tap(find.byKey(const Key('history-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tout effacer'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Les 2 sessions'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Tout effacer'));
    await tester.pumpAndSettle();

    expect(find.text('Aucune session pour l’instant'), findsOneWidget);
    expect(find.byKey(const Key('history-menu')), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Reprendre la session'), findsOneWidget);
  });

  testWidgets('a session with a team game is marked', (tester) async {
    final storage = await AppStorage.withTwoPlayers();
    final players = await InMemoryPlayerCatalog(storage.players).active();
    (await InMemorySessionRepository(storage.sessions).create())
      ..startGame([Player.team(players)], config: const GolfConfig())
      ..endSession();
    await pumpApp(tester, storage);
    await openHistory(tester);

    expect(find.byIcon(Icons.groups_outlined), findsOneWidget);
  });

  testWidgets('the open session is not listed: it is resumed instead', (
    tester,
  ) async {
    final storage = await AppStorage.withTwoPlayers();
    final players = await InMemoryPlayerCatalog(storage.players).active();
    (await InMemorySessionRepository(storage.sessions).create())
      ..startGame(players)
      ..submitVisitTotal(60);
    await pumpApp(tester, storage);
    expect(find.text('Reprendre la session'), findsOneWidget);

    await openHistory(tester);
    expect(find.text('Aucune session pour l’instant'), findsOneWidget);
  });

  testWidgets('a session can be deleted after confirming', (tester) async {
    final storage = await AppStorage.withTwoPlayers();
    await playedSession(storage);
    await pumpApp(tester, storage);
    await openHistory(tester);
    await tester.tap(find.text('Joueur 1, Joueur 2 · 1 partie'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Supprimer la session'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Partie 1 · 40 Double-out'), findsOneWidget);

    await tester.tap(find.byTooltip('Supprimer la session'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
    await tester.pumpAndSettle();

    expect(find.text('Aucune session pour l’instant'), findsOneWidget);
  });

  testWidgets('a session without X01 or cricket shows no empty stats table', (
    tester,
  ) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await launchGame(tester, const ['Joueur 1', 'Joueur 2'], 'Shanghai');
    for (final key in ['S1', 'D1', 'T1']) {
      await tester.tap(find.text(key));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terminer la session'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terminer'));
    await tester.pumpAndSettle();
    await openHistory(tester);
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    expect(find.text('Partie 1 · Shanghai 1–7'), findsOneWidget);
    expect(find.text('Stats de la session'), findsNothing);
    expect(find.text('pts'), findsOneWidget);
  });
}
