import 'dart:io';

import 'package:darts_points_counter/app_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('store version is 1.0.0 in app and pubspec', () {
    expect(appVersionName, '1.0.0');
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains(RegExp(r'^version:\s*1\.0\.0\+\d+', multiLine: true)));
  });
}
