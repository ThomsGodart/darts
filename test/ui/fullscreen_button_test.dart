import 'package:darts_points_counter/ui/app_fullscreen.dart';
import 'package:darts_points_counter/ui/fullscreen_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_test_harness.dart';

void main() {
  testWidgets('the home screen offers fullscreen when the platform can', (
    tester,
  ) async {
    var active = false;
    final fullscreen = AppFullscreen(
      supported: true,
      enter: () async => active = true,
      exit: () async => active = false,
      readActive: () => active,
    );
    addTearDown(fullscreen.dispose);

    await pumpApp(
      tester,
      await AppStorage.withTwoPlayers(),
      fullscreen: fullscreen,
    );

    expect(find.byKey(const Key('toggle-fullscreen')), findsOneWidget);
    expect(find.byIcon(Icons.fullscreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('toggle-fullscreen')));
    await tester.pump();

    expect(fullscreen.isActive, isTrue);
    expect(find.byIcon(Icons.fullscreen_exit), findsOneWidget);

    await tester.tap(find.byKey(const Key('toggle-fullscreen')));
    await tester.pump();
    expect(fullscreen.isActive, isFalse);
  });

  testWidgets('the game bar offers the same fullscreen control', (
    tester,
  ) async {
    var active = false;
    final fullscreen = AppFullscreen(
      supported: true,
      enter: () async => active = true,
      exit: () async => active = false,
      readActive: () => active,
    );
    addTearDown(fullscreen.dispose);

    await pumpApp(
      tester,
      await AppStorage.withTwoPlayers(),
      fullscreen: fullscreen,
    );
    await launchGame(tester);

    expect(find.byKey(const Key('toggle-fullscreen')), findsOneWidget);
    await tester.tap(find.byKey(const Key('toggle-fullscreen')));
    await tester.pump();
    expect(fullscreen.isActive, isTrue);
  });

  testWidgets('leaving fullscreen outside the app puts the button back', (
    tester,
  ) async {
    late void Function(bool active) platformChanged;
    var listening = false;
    final fullscreen = AppFullscreen(
      supported: true,
      enter: () async {},
      exit: () async {},
      readActive: () => false,
      listen: (onChanged) {
        platformChanged = onChanged;
        listening = true;
      },
      stopListening: () => listening = false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FullscreenButton(fullscreen: fullscreen)),
      ),
    );
    await tester.tap(find.byKey(const Key('toggle-fullscreen')));
    await tester.pump();
    expect(find.byIcon(Icons.fullscreen_exit), findsOneWidget);

    // Escape in a browser: the platform says so, no button was tapped.
    platformChanged(false);
    await tester.pump();

    expect(fullscreen.isActive, isFalse);
    expect(find.byIcon(Icons.fullscreen), findsOneWidget);

    fullscreen.dispose();
    expect(listening, isFalse);
  });

  testWidgets('unsupported platforms hide the button', (tester) async {
    final fullscreen = AppFullscreen(supported: false);
    addTearDown(fullscreen.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FullscreenButton(fullscreen: fullscreen)),
      ),
    );

    expect(find.byKey(const Key('toggle-fullscreen')), findsNothing);
  });
}
