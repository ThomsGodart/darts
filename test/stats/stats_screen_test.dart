import 'package:darts_points_counter/session/session.dart';
import 'package:darts_points_counter/settings/app_settings.dart';
import 'package:darts_points_counter/stats/stat_lines.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_test_harness.dart';

Future<void> openStats(WidgetTester tester) async {
  await tester.tap(find.text('Statistiques'));
  await tester.pumpAndSettle();
}

/// The value of the line [label] for the player in column [column].
String valueOf(WidgetTester tester, String label, [int column = 0]) {
  final row = tester.getCenter(find.text(label)).dy;
  final values = find.descendant(
    of: find.byKey(const Key('stats-table')),
    matching: find.byType(Text),
  );
  final onRow = [
    for (final element in values.evaluate())
      if ((tester.getCenter(find.byWidget(element.widget)).dy - row).abs() < 1)
        element.widget as Text,
  ];
  return onRow[column].data!;
}

void main() {
  testWidgets('empty before anything is played', (tester) async {
    await pumpApp(tester, AppStorage());
    await openStats(tester);

    expect(find.text('Aucune partie jouée pour l’instant'), findsOneWidget);
    expect(find.byKey(const Key('stats-players')), findsNothing);
  });

  testWidgets('shows the players side by side over ended and open sessions', (
    tester,
  ) async {
    final storage = await AppStorage.withTwoPlayers();
    final players = await InMemoryPlayerCatalog(storage.players).active();
    final repository = InMemorySessionRepository(storage.sessions);
    (await repository.create())
      ..startGame(players, config: const X01Config(startScore: 101))
      ..submitVisitTotal(101, dartsAtCheckout: 3)
      ..endSession();
    (await repository.create())
      ..startGame(players, config: const X01Config(startScore: 101))
      ..submitVisitTotal(101, dartsAtCheckout: 3);

    await pumpApp(tester, storage);
    await openStats(tester);

    expect(find.text('Joueur 1'), findsOneWidget);
    expect(find.text('Joueur 2'), findsOneWidget);
    expect(valueOf(tester, 'Parties terminées'), '2');
    expect(valueOf(tester, 'Victoires'), '2 (100 %)');
    expect(valueOf(tester, 'Victoires', 1), '0 (0 %)');
    expect(valueOf(tester, 'Meilleure finition'), '101');
    expect(valueOf(tester, 'Manche la plus courte'), '3 fl.');
    // No match of several legs was played: nothing about matches.
    expect(find.text('Matchs joués'), findsNothing);
  });

  testWidgets('one game at a time: a cricket game shows no X01 average', (
    tester,
  ) async {
    final storage = await AppStorage.withTwoPlayers();
    final players = await InMemoryPlayerCatalog(storage.players).active();
    (await InMemorySessionRepository(storage.sessions).create())
      ..startGame(players, config: const X01Config(startScore: 101))
      ..submitVisitTotal(101, dartsAtCheckout: 3)
      ..startGame(players, config: const CricketConfig())
      ..throwDart(const Dart.treble(20))
      ..endVisit()
      ..endSession();

    await pumpApp(tester, storage);
    await openStats(tester);
    expect(find.text('Moyenne'), findsOneWidget);
    expect(find.text('MPR'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Cricket'));
    await tester.pumpAndSettle();
    expect(find.text('Moyenne'), findsNothing);
    expect(valueOf(tester, 'MPR'), '3.0');
    expect(valueOf(tester, 'Meilleur round'), '3 marques');
  });

  testWidgets('a period leaves out the games started before it', (
    tester,
  ) async {
    final storage = await AppStorage.withTwoPlayers();
    final players = await InMemoryPlayerCatalog(storage.players).active();
    final repository = InMemorySessionRepository(storage.sessions);
    final today = DateTime.now();
    for (final daysAgo in [40, 10, 0]) {
      storage.sessions.now = () => today.subtract(Duration(days: daysAgo));
      (await repository.create())
        ..startGame(players, config: const X01Config(startScore: 101))
        ..submitVisitTotal(101, dartsAtCheckout: 3)
        ..endSession();
    }

    await pumpApp(tester, storage);
    await openStats(tester);
    expect(valueOf(tester, 'Parties terminées'), '3');

    for (final (period, games) in [
      ('30 j', '2'),
      ('7 j', '1'),
      ('24 h', '1'),
    ]) {
      await tester.tap(find.text(period));
      await tester.pumpAndSettle();
      expect(valueOf(tester, 'Parties terminées'), games, reason: period);
    }
  });

  testWidgets('the players shown are chosen, and the choice is kept', (
    tester,
  ) async {
    final storage = await AppStorage.withTwoPlayers();
    final players = await InMemoryPlayerCatalog(storage.players).active();
    (await InMemorySessionRepository(storage.sessions).create())
      ..startGame(players, config: const X01Config(startScore: 101))
      ..submitVisitTotal(101, dartsAtCheckout: 3)
      ..endSession();
    final store = InMemorySettingsStore();

    await pumpApp(tester, storage, settingsStore: store);
    await openStats(tester);
    await tester.tap(find.byKey(const Key('stats-players')));
    await tester.pumpAndSettle();
    // Everyone is shown: the one shortcut left is to clear them all.
    expect(find.text('Tout décocher'), findsOneWidget);
    expect(find.text('Tout cocher'), findsNothing);
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Joueur 2'));
    await tester.pump();
    expect(find.text('Tout cocher'), findsOneWidget);
    expect(find.text('Tout décocher'), findsNothing);
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    expect(find.text('Joueur 1'), findsOneWidget);
    expect(find.text('Joueur 2'), findsNothing);

    // Closed and opened again, and after a relaunch: still left out.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await openStats(tester);
    expect(find.text('Joueur 2'), findsNothing);
    final relaunched = AppSettings(store);
    await relaunched.load();
    expect(relaunched.statsHiddenPlayers, {players.last.id});
  });

  testWidgets('team games can be told apart from solo ones', (tester) async {
    final storage = await AppStorage.withPlayers(const ['Ana', 'Bob', 'Cléo']);
    final [ana, bob, cleo] = await InMemoryPlayerCatalog(storage.players)
        .active();
    (await InMemorySessionRepository(storage.sessions).create())
      ..startGame([
        Player.team([ana, bob]),
        cleo,
      ], config: const X01Config(startScore: 101))
      ..submitVisitTotal(101, dartsAtCheckout: 3)
      ..startGame([ana, cleo], config: const X01Config(startScore: 101))
      ..submitVisitTotal(101, dartsAtCheckout: 3)
      ..endSession();

    await pumpApp(tester, storage);
    await openStats(tester);
    expect(valueOf(tester, 'Parties terminées'), '2');

    await tester.tap(find.text('En équipe'));
    await tester.pumpAndSettle();
    expect(find.text('Cléo'), findsNothing);
    expect(valueOf(tester, 'Parties terminées'), '1');

    await tester.tap(find.text('Solo'));
    await tester.pumpAndSettle();
    expect(find.text('Bob'), findsNothing);
    expect(find.text('Cléo'), findsOneWidget);
  });

  test('a game that ends on no score has no score lines', () {
    const killer = ScoreStats(
      player: Player(id: 'a', name: 'A'),
      gamesPlayed: 2,
      gamesWon: 1,
      averageScore: null,
      bestScore: null,
    );
    expect(
      [
        for (final (label, values) in statLines([killer]))
          '$label ${values.single}',
      ],
      ['Parties terminées 2', 'Victoires 1 (50 %)'],
    );
    expect(statLines(const []), isEmpty);
  });
}
