import 'package:darts_points_counter/session/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_test_harness.dart';

Future<AppStorage> threePlayers() async {
  final storage = AppStorage();
  final catalog = InMemoryPlayerCatalog(storage.players);
  await catalog.add('Joueur 1');
  await catalog.add('Joueur 2');
  await catalog.add('Joueur 3');
  return storage;
}

void main() {
  testWidgets('Killer starts in attribution with a number pad', (tester) async {
    await pumpApp(tester, await threePlayers());
    await launchGame(tester, const [
      'Joueur 1',
      'Joueur 2',
      'Joueur 3',
    ], 'Killer');

    expect(find.byKey(const Key('killer-board')), findsOneWidget);
    expect(find.text('Attribution des chiffres'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
  });

  testWidgets('assigning three numbers reaches the doubles grid', (
    tester,
  ) async {
    await pumpApp(tester, await threePlayers());
    await launchGame(tester, const [
      'Joueur 1',
      'Joueur 2',
      'Joueur 3',
    ], 'Killer');
    await tester.tap(find.text('20'));
    await tester.pump();
    await tester.tap(find.text('19'));
    await tester.pump();
    await tester.tap(find.text('18'));
    await tester.pumpAndSettle();

    expect(find.text('D20'), findsOneWidget);
    expect(find.text('Fin de tour'), findsOneWidget);
  });
}
