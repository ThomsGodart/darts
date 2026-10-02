import 'package:darts_points_counter/app.dart';
import 'package:darts_points_counter/soiree/soiree.dart';
import 'package:darts_points_counter/backend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the app starts without any network or backend', (tester) async {
    await tester.pumpWidget(DartsApp(repository: InMemorySoireeRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Darts'), findsOneWidget);
  });

  test('a failing backend init never escapes to the caller', () async {
    await expectLater(
      initBackend(initializer: () async => throw Exception('offline')),
      completes,
    );
  });
}
