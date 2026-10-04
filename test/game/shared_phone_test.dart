import 'package:darts_points_counter/game/game_screen.dart';
import 'package:darts_points_counter/game/screen_awake.dart';
import 'package:darts_points_counter/session/session.dart';
import 'package:darts_points_counter/session_controller.dart';
import 'package:darts_points_counter/theme/app_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_test_harness.dart' show switchToTotals;

const alice = Player(id: 'alice', name: 'Alice');
const bob = Player(id: 'bob', name: 'Bob');

class FakeScreenAwake implements ScreenAwake {
  bool isOn = false;

  @override
  Future<void> keepOn() async => isOn = true;

  @override
  Future<void> release() async => isOn = false;
}

Future<SessionController> pumpGame(
  WidgetTester tester, {
  ScreenAwake? screenAwake,
  int startScore = 501,
}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  final controller = SessionController(Session(InMemoryJournal()))
    ..startGame([alice, bob], config: X01Config(startScore: startScore));
  await tester.pumpWidget(
    MaterialApp(
      theme: themeById(defaultThemeId),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => GameScreen(
                    controller: controller,
                    screenAwake: screenAwake ?? FakeScreenAwake(),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  await switchToTotals(tester);
  return controller;
}

void main() {
  group('turn change', () {
    testWidgets('a banner names the next player', (tester) async {
      await pumpGame(tester);
      expect(find.byKey(const Key('turn-banner')), findsNothing);

      await tester.tap(find.widgetWithText(FilledButton, '60'));
      await tester.pump();

      final banner = find.byKey(const Key('turn-banner'));
      expect(banner, findsOneWidget);
      expect(
        find.descendant(of: banner, matching: find.textContaining('Bob')),
        findsOneWidget,
      );

      await tester.pumpAndSettle();
      expect(find.byKey(const Key('turn-banner')), findsNothing);
    });

    testWidgets('no banner on an undo', (tester) async {
      final controller = await pumpGame(tester);
      await tester.tap(find.widgetWithText(FilledButton, '60'));
      await tester.pumpAndSettle();

      controller.undo();
      await tester.pump();
      expect(find.byKey(const Key('turn-banner')), findsNothing);
    });

    testWidgets('an undo during the banner hides it', (tester) async {
      final controller = await pumpGame(tester);
      await tester.tap(find.widgetWithText(FilledButton, '60'));
      await tester.pump();
      expect(find.byKey(const Key('turn-banner')), findsOneWidget);

      controller.undo();
      await tester.pump();
      expect(find.byKey(const Key('turn-banner')), findsNothing);
    });

    testWidgets('the banner never blocks the next input', (tester) async {
      await pumpGame(tester);
      await tester.tap(find.widgetWithText(FilledButton, '60'));
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, '45'));
      await tester.pump();
      expect(find.text('456'), findsOneWidget);
    });
  });

  group('screen kept awake', () {
    testWidgets('during a game, released when it ends', (tester) async {
      final screenAwake = FakeScreenAwake();
      final controller = await pumpGame(
        tester,
        screenAwake: screenAwake,
        startScore: 40,
      );
      expect(screenAwake.isOn, isTrue);

      controller.submitVisitTotal(40, dartsAtCheckout: 1);
      await tester.pump();
      expect(screenAwake.isOn, isFalse);

      controller.undo();
      await tester.pump();
      expect(screenAwake.isOn, isTrue);
    });

    testWidgets('released when leaving the game screen', (tester) async {
      final screenAwake = FakeScreenAwake();
      await pumpGame(tester, screenAwake: screenAwake);

      Navigator.of(tester.element(find.byType(GameScreen))).pop();
      await tester.pumpAndSettle();
      expect(screenAwake.isOn, isFalse);
    });
  });

  testWidgets('no player-facing tap-count HUD', (tester) async {
    await pumpGame(tester);
    await tester.tap(find.widgetWithText(FilledButton, '60'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '4'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '5'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'OK'));
    await tester.pump();

    expect(find.textContaining('taps/volée'), findsNothing);
  });
}
