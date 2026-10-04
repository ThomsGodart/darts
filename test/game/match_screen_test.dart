import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_test_harness.dart';
import 'game_screen_test.dart' show playVisits;

String matchScore(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('match-score'))).data!;

void main() {
  testWidgets('a match counts its legs up to its winner', (tester) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await launchGame(
      tester,
      const ['Joueur 1', 'Joueur 2'],
      null,
      const ['1er à 2'],
    );
    expect(find.textContaining('Joueur 1 0 · Joueur 2 0'), findsOneWidget);

    await playVisits(tester, [180, 26, 180, 26, 141]);
    await tester.pumpAndSettle();
    expect(find.text('Joueur 1 gagne la manche'), findsOneWidget);
    expect(matchScore(tester), 'Manches : Joueur 1 1 · Joueur 2 0');
    expect(find.text('Rejouer'), findsNothing);

    // The next leg: whoever started the last one now throws second.
    await tester.tap(find.text('Manche suivante'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('active-name'))).data,
      'Joueur 2',
    );
    await playVisits(tester, [26, 180, 26, 180, 26, 141]);
    await tester.pumpAndSettle();

    expect(find.text('Joueur 1 gagne le match !'), findsOneWidget);
    // The score line keeps its order, whoever threw first.
    expect(matchScore(tester), 'Manches : Joueur 1 2 · Joueur 2 0');
    expect(find.text('Rejouer'), findsOneWidget);
  });

  testWidgets('sets are only offered for a match in legs', (tester) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await tester.tap(find.text('Nouvelle session'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sets-to-win')), findsNothing);
    await tapInSetup(tester, '1er à 3');
    await tapInSetup(tester, '2 sets');
    expect(find.byKey(const Key('sets-to-win')), findsOneWidget);

    await tapInSetup(tester, '1 manche');
    expect(find.byKey(const Key('sets-to-win')), findsNothing);
  });

  testWidgets('a single leg still says who wins, with nothing about a match', (
    tester,
  ) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await launchGame(tester);
    await playVisits(tester, [180, 26, 180, 26, 141]);
    await tester.pumpAndSettle();

    expect(find.text('Joueur 1 gagne !'), findsOneWidget);
    expect(find.byKey(const Key('match-score')), findsNothing);
  });
}
