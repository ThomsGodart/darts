import 'package:darts_points_counter/crash_reporting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('debug builds skip crash reporting by default', () async {
    var called = false;
    await expectLater(
      initCrashReporting(
        releaseOnly: false,
        initializer: () async {
          called = true;
        },
      ),
      completes,
    );
    expect(called, isFalse);
  });

  test('release builds run the initializer', () async {
    var called = false;
    await expectLater(
      initCrashReporting(
        releaseOnly: true,
        initializer: () async {
          called = true;
        },
      ),
      completes,
    );
    expect(called, isTrue);
  });

  test('a failing initializer never escapes to the caller', () async {
    await expectLater(
      initCrashReporting(
        releaseOnly: true,
        initializer: () async => throw Exception('no firebase'),
      ),
      completes,
    );
  });

  test('default release init is a quiet no-op without Firebase config', () async {
    await expectLater(
      initCrashReporting(releaseOnly: true),
      completes,
    );
  });
}
