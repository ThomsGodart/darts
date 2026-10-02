import 'package:darts_points_counter/app.dart';
import 'package:darts_points_counter/soiree/soiree.dart';
import 'package:darts_points_counter/game/visit_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

String activeRemaining(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('active-remaining'))).data!;

Future<void> startGame(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(DartsApp(repository: InMemorySoireeRepository()));
  await tester.tap(find.text('Nouvelle partie 501'));
  await tester.pumpAndSettle();
}

Future<void> quickScore(WidgetTester tester, int score) async {
  await tester.tap(find.widgetWithText(ActionChip, '$score'));
  await tester.pump();
}

/// Enters [scores] as visits, quick-scores when available.
Future<void> playVisits(WidgetTester tester, List<int> scores) async {
  for (final score in scores) {
    if (quickScores.contains(score)) {
      await quickScore(tester, score);
    } else {
      await typeTotal(tester, score);
    }
  }
}

Future<void> typeTotal(WidgetTester tester, int score) async {
  for (final digit in '$score'.split('')) {
    await tester.tap(find.widgetWithText(FilledButton, digit));
    // OK is only enabled once a digit has been rendered.
    await tester.pump();
  }
  await tester.tap(find.widgetWithText(FilledButton, 'OK'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a quick-score lowers the remaining and passes the turn', (
    tester,
  ) async {
    await startGame(tester);
    expect(activeRemaining(tester), '501');

    await tester.tap(find.widgetWithText(ActionChip, '60'));
    await tester.pump();

    // Joueur 2 is now up; Joueur 1 waits with 441.
    expect(find.text('Joueur 2'), findsOneWidget);
    expect(activeRemaining(tester), '501');
    expect(find.text('441'), findsOneWidget);
  });

  testWidgets('a typed total is submitted with OK', (tester) async {
    await startGame(tester);

    await tester.tap(find.widgetWithText(FilledButton, '4'));
    await tester.tap(find.widgetWithText(FilledButton, '5'));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('typed-total'))).data,
      '45',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'OK'));
    await tester.pump();
    expect(find.text('456'), findsOneWidget);
  });

  testWidgets('a checkout asks for the dart count, then names the winner', (
    tester,
  ) async {
    await startGame(tester);
    // Joueur 1 down to 40; Joueur 2 scores 26s.
    await playVisits(tester, [180, 26, 180, 26, 101, 26]);

    await typeTotal(tester, 40);
    expect(find.text('Combien de fléchettes ?'), findsOneWidget);
    final inDialog = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(FilledButton),
    );
    expect(inDialog, findsNWidgets(3));

    await tester.tap(find.descendant(of: inDialog, matching: find.text('2')));
    await tester.pumpAndSettle();
    expect(find.text('Joueur 1 gagne !'), findsOneWidget);
  });

  testWidgets('a checkout with a single possible dart count needs no dialog', (
    tester,
  ) async {
    await startGame(tester);
    await playVisits(tester, [180, 26, 180, 26]);

    // 141 double-out can only be done in three darts.
    await typeTotal(tester, 141);
    expect(find.text('Combien de fléchettes ?'), findsNothing);
    expect(find.text('Joueur 1 gagne !'), findsOneWidget);
  });

  testWidgets('a bust is flagged on the player who busted', (tester) async {
    await startGame(tester);
    await playVisits(tester, [180, 26, 180, 26]);

    await typeTotal(tester, 160);
    expect(find.textContaining('BUST'), findsOneWidget);
    expect(find.text('141'), findsOneWidget);
  });

  testWidgets('undo takes back visits, even the checkout', (tester) async {
    await startGame(tester);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Annuler'),
          )
          .onPressed,
      isNull,
    );

    await playVisits(tester, [180, 26, 180, 26, 141]);
    expect(find.text('Joueur 1 gagne !'), findsOneWidget);

    await tester.tap(find.text('Annuler le checkout'));
    await tester.pump();
    expect(find.text('Joueur 1 gagne !'), findsNothing);
    expect(activeRemaining(tester), '141');

    await tester.tap(find.text('Annuler'));
    await tester.pump();
    expect(find.text('Joueur 2'), findsOneWidget);
    // Joueur 2's second 26 is taken back: back to 501 - 26.
    expect(activeRemaining(tester), '475');
  });

  testWidgets('a visit entered dart by dart, then back to total mode', (
    tester,
  ) async {
    await startGame(tester);

    await tester.tap(find.text('Fléchettes'));
    await tester.pump();
    await tester.tap(find.text('Triple'));
    await tester.pump();
    await tester.tap(find.text('T20'));
    await tester.pump();

    final darts = find.byKey(const Key('darts-in-visit'));
    expect(tester.widget<Text>(darts).data, startsWith('T20'));
    expect(activeRemaining(tester), '441');

    // Back to single after each dart.
    await tester.tap(find.text('5'));
    await tester.tap(find.text('Bull'));
    await tester.pump();

    expect(find.text('Joueur 2'), findsOneWidget);
    expect(find.text('386'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, '60'), findsOneWidget);
  });

  testWidgets('a dart-by-dart visit cannot switch back to total', (
    tester,
  ) async {
    await startGame(tester);
    await tester.tap(find.text('Fléchettes'));
    await tester.pump();
    await tester.tap(find.text('20'));
    await tester.pump();

    await tester.tap(find.text('Total'));
    await tester.pump();
    expect(find.byKey(const Key('darts-in-visit')), findsOneWidget);
  });
}
