import 'package:darts_points_counter/app_version.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_test_harness.dart';

void main() {
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
}
