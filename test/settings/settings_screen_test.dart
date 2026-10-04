import 'package:darts_points_counter/app_version.dart';
import 'package:darts_points_counter/settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_test_harness.dart';

void main() {
  // The bundle caches the privacy text across tests, in a future of the
  // test that asked first: it would never complete in the next one.
  setUp(rootBundle.clear);

  testWidgets('Home opens Settings with version and privacy', (tester) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());

    await tester.tap(find.byKey(const Key('settings-button')));
    await tester.pumpAndSettle();

    expect(find.text('Réglages'), findsOneWidget);
    expect(find.byKey(const Key('app-version')), findsOneWidget);
    expect(find.text(appVersionName), findsOneWidget);
    expect(find.byKey(const Key('privacy-policy')), findsOneWidget);
    expect(find.textContaining('local-first'), findsOneWidget);
    expect(find.textContaining('Crashlytics'), findsOneWidget);
    expect(find.textContaining('analytics comportementaux'), findsOneWidget);
  });

  group('Verrouiller en portrait', () {
    /// Every set of orientations the app asked the system to allow, in
    /// order, as the system names them.
    List<List<String>> orientationsAsked(WidgetTester tester) {
      final asked = <List<String>>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'SystemChrome.setPreferredOrientations') {
            asked.add([...call.arguments as List].cast<String>());
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      return asked;
    }

    testWidgets('off by default: the game screen follows the phone', (
      tester,
    ) async {
      final asked = orientationsAsked(tester);
      await pumpApp(tester, await AppStorage.withTwoPlayers());
      await launchGame(tester);

      expect(asked.last, contains('DeviceOrientation.landscapeLeft'));
      expect(asked.last, contains('DeviceOrientation.portraitUp'));
    });

    testWidgets('once on, the game screen only allows portrait', (
      tester,
    ) async {
      final asked = orientationsAsked(tester);
      await pumpApp(tester, await AppStorage.withTwoPlayers());
      await tester.tap(find.byKey(const Key('settings-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('portrait-lock')));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      await launchGame(tester);
      expect(asked.last, ['DeviceOrientation.portraitUp']);
    });

    testWidgets('the choice is kept for the next launch', (tester) async {
      final store = InMemorySettingsStore();
      final storage = await AppStorage.withTwoPlayers();
      await pumpApp(tester, storage, settingsStore: store);
      await tester.tap(find.byKey(const Key('settings-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('portrait-lock')));
      await tester.pumpAndSettle();

      // Relaunch on the same stores.
      await tester.pumpWidget(const SizedBox());
      await pumpApp(tester, storage, settingsStore: store);
      await tester.tap(find.byKey(const Key('settings-button')));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<SwitchListTile>(find.byKey(const Key('portrait-lock')))
            .value,
        isTrue,
      );
    });
  });
}
