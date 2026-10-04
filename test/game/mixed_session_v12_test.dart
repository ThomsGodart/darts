import 'package:darts_points_counter/session/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_test_harness.dart';
import 'session_flow_test.dart' show joueur1Wins;

Future<AppStorage> threePlayers() async {
  final storage = AppStorage();
  final catalog = InMemoryPlayerCatalog(storage.players);
  await catalog.add('Joueur 1');
  await catalog.add('Joueur 2');
  await catalog.add('Joueur 3');
  return storage;
}

void main() {
  testWidgets('Partie suivante switches from X01 to Shanghai', (tester) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await launchGame(tester);
    await joueur1Wins(tester);

    await tester.tap(find.text('Partie suivante'));
    await tester.pumpAndSettle();
    await tapInSetup(tester, 'Shanghai');
    await tester.tap(find.text('Lancer la partie'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('shanghai-board')), findsOneWidget);
  });

  testWidgets('Partie suivante switches from Shanghai to Killer', (
    tester,
  ) async {
    await pumpApp(tester, await threePlayers());
    await launchGame(tester, const [
      'Joueur 1',
      'Joueur 2',
      'Joueur 3',
    ], 'Shanghai');
    // Instant shanghai for Joueur 1.
    await tester.tap(find.text('S1'));
    await tester.pump();
    await tester.tap(find.text('D1'));
    await tester.pump();
    await tester.tap(find.text('T1'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Partie suivante'));
    await tester.pumpAndSettle();
    await tapInSetup(tester, 'Killer');
    await tester.tap(find.text('Lancer la partie'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('killer-board')), findsOneWidget);
  });
}
