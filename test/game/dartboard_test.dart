import 'dart:math';

import 'package:darts_points_counter/game/dartboard_geometry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_test_harness.dart';
import 'game_screen_test.dart' show activeRemaining;

final board = find.byKey(const Key('dartboard'));
final aimed = find.byKey(const Key('dartboard-aimed'));

/// Where [radius] (0 centre, 1 edge) and [degrees] clockwise from the top
/// are on the board on screen.
Offset spot(WidgetTester tester, double radius, double degrees) {
  final rect = tester.getRect(board);
  final angle = degrees * pi / 180;
  return rect.center +
      Offset(sin(angle), -cos(angle)) * (radius * rect.width / 2);
}

const treble = (DartboardRings.trebleInner + DartboardRings.trebleOuter) / 2;
const double_ = (DartboardRings.doubleInner + 1) / 2;

String dartsInVisit(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('darts-in-visit'))).data!;

Future<void> launchOnBoard(WidgetTester tester, [String? game]) async {
  await pumpApp(tester, await AppStorage.withTwoPlayers());
  await launchGame(
    tester,
    const ['Joueur 1', 'Joueur 2'],
    game,
    [if (game == 'Cricket') 'Clavier fléchettes'],
    false,
  );
  await tester.tap(find.text('Cible'));
  await tester.pump();
}

void main() {
  testWidgets('touching the board enters the dart under the finger', (
    tester,
  ) async {
    await launchOnBoard(tester);

    await tester.tapAt(spot(tester, treble, 0));
    await tester.pump();
    expect(dartsInVisit(tester), startsWith('T20'));
    expect(activeRemaining(tester), '441');

    await tester.tapAt(spot(tester, double_, 144)); // 2 is 8 numbers on
    await tester.pump();
    await tester.tapAt(spot(tester, 0, 0));
    await tester.pumpAndSettle();

    // T20 + D2 + bull = 114: the visit is over.
    expect(find.text('387'), findsOneWidget);
  });

  testWidgets('the board fits the pane and stays for the next visit', (
    tester,
  ) async {
    await launchOnBoard(tester);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Fin de tour'));
    await tester.pumpAndSettle();
    expect(board, findsOneWidget);
    expect(find.text('Triple'), findsNothing);
  });

  testWidgets(
    'the dart is named while the finger is down, entered on release',
    (tester) async {
      await launchOnBoard(tester);

      final gesture = await tester.startGesture(spot(tester, double_, 0));
      await tester.pump();
      expect(
        find.descendant(of: aimed, matching: find.text('D20')),
        findsOneWidget,
      );
      expect(dartsInVisit(tester), startsWith('–'));

      // Sliding corrects the aim before anything is entered.
      await gesture.moveTo(spot(tester, treble, 18));
      await tester.pump();
      expect(
        find.descendant(of: aimed, matching: find.text('T1')),
        findsOneWidget,
      );

      await gesture.up();
      await tester.pump();
      expect(aimed, findsNothing);
      expect(dartsInVisit(tester), startsWith('T1'));
    },
  );

  testWidgets('sliding off the board enters nothing', (tester) async {
    await launchOnBoard(tester);

    final gesture = await tester.startGesture(spot(tester, 0.5, 90));
    await tester.pump();
    expect(aimed, findsOneWidget);
    await gesture.moveTo(tester.getRect(board).topLeft + const Offset(2, 2));
    await tester.pump();
    expect(aimed, findsNothing);
    await gesture.up();
    await tester.pump();

    expect(dartsInVisit(tester), startsWith('–'));
  });

  testWidgets('a miss has its key under the board', (tester) async {
    await launchOnBoard(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Raté'));
    await tester.pump();
    expect(dartsInVisit(tester), startsWith('0'));
  });

  testWidgets('cricket on the dart keypad can use the board too', (
    tester,
  ) async {
    await launchOnBoard(tester, 'Cricket');

    await tester.tapAt(spot(tester, treble, 0));
    await tester.pump();

    expect(dartsInVisit(tester), startsWith('T20'));
    expect(find.byKey(const Key('mark-closed')), findsOneWidget);
    // No totals in cricket, and no miss key: the visit is ended instead.
    expect(find.text('Total'), findsNothing);
    expect(find.text('Raté'), findsNothing);
  });

  testWidgets('a total cannot be chosen once a dart is on the board', (
    tester,
  ) async {
    await launchOnBoard(tester);
    await tester.tapAt(spot(tester, 0.3, 0));
    await tester.pump();

    await tester.tap(find.text('Total'));
    await tester.pump();
    expect(board, findsOneWidget);
  });

  testWidgets('the board fits in landscape', (tester) async {
    await launchOnBoard(tester);
    await tester.binding.setSurfaceSize(const Size(900, 500));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpAndSettle();

    expect(board, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
