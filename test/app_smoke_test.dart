import 'package:darts_points_counter/backend.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_test_harness.dart';

void main() {
  testWidgets('the app starts without any network or backend', (tester) async {
    await pumpApp(tester, AppStorage());

    expect(find.text('Darts'), findsOneWidget);
    expect(find.text('Nouvelle session'), findsOneWidget);
  });

  test('a failing backend init never escapes to the caller', () async {
    await expectLater(
      initBackend(initializer: () async => throw Exception('offline')),
      completes,
    );
  });

  test('initBackend without dart-defines is a quiet no-op', () async {
    // No SUPABASE_* --dart-define in the test process; must not throw.
    await expectLater(initBackend(), completes);
  });
}
