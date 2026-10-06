import 'package:darts_points_counter/backend.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_test_harness.dart';

void main() {
  testWidgets('the app starts without any network or backend', (tester) async {
    await pumpApp(tester, AppStorage());

    expect(find.text('Darts'), findsOneWidget);
    expect(find.text('Nouvelle session'), findsOneWidget);
  });

  test('a build without a backend has nothing to share over', () {
    expect(shareTransport(url: ''), isNull);
    expect(shareTransport(publishableKey: ''), isNull);
  });

  test('making the share transport does not touch the network', () {
    expect(shareTransport(), isNotNull);
  });
}
