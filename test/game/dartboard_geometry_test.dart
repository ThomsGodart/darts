import 'dart:math';

import 'package:darts_points_counter/game/dartboard_geometry.dart';
import 'package:darts_points_counter/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

/// The dart at [radius] (0 centre, 1 edge) and [degrees] clockwise from
/// the top of a board of side 200.
Dart? at(double radius, double degrees) {
  final angle = degrees * pi / 180;
  return dartAt(
    dx: 100 + 100 * radius * sin(angle),
    dy: 100 - 100 * radius * cos(angle),
    side: 200,
  );
}

void main() {
  test('the bull in the middle, the outer bull around it', () {
    expect(at(0, 0), Dart.bull);
    expect(at(DartboardRings.bull - 0.01, 123), Dart.bull);
    expect(at(DartboardRings.bull + 0.01, 123), Dart.outerBull);
    expect(at(DartboardRings.outerBull - 0.01, 300), Dart.outerBull);
  });

  test('from the middle out: single, treble, single, double', () {
    expect(at(DartboardRings.outerBull + 0.02, 0), const Dart.single(20));
    expect(at(DartboardRings.trebleInner + 0.02, 0), const Dart.treble(20));
    expect(at(DartboardRings.trebleOuter + 0.02, 0), const Dart.single(20));
    expect(at(DartboardRings.doubleInner + 0.02, 0), const Dart.double(20));
    expect(at(0.99, 0), const Dart.double(20));
  });

  test('past the edge there is no dart', () {
    expect(at(1.01, 0), isNull);
    expect(at(1.4, 45), isNull);
  });

  test('the numbers go round as on a real board', () {
    expect(boardNumbers, hasLength(20));
    expect(boardNumbers.toSet(), {for (var n = 1; n <= 20; n++) n});
    expect(
      [for (var i = 0; i < 20; i++) at(0.3, i * 18.0)!.sector],
      [20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5],
    );
  });

  test('20 is at the top, 6 on the right, 3 at the bottom, 11 on the left', () {
    expect(at(0.3, 0)!.sector, 20);
    expect(at(0.3, 90)!.sector, 6);
    expect(at(0.3, 180)!.sector, 3);
    expect(at(0.3, 270)!.sector, 11);
  });

  test('a number spans nine degrees either side of its middle', () {
    expect(at(0.3, 8.5)!.sector, 20);
    expect(at(0.3, 9.5)!.sector, 1);
    expect(at(0.3, 351.5)!.sector, 20);
    expect(at(0.3, 350.5)!.sector, 5);
  });

  test('the rings are wider than a real board’s, for a finger', () {
    // A real treble is 8 mm on a 170 mm radius, a real double the same.
    const real = 8 / 170;
    expect(
      DartboardRings.trebleOuter - DartboardRings.trebleInner,
      greaterThan(3 * real),
    );
    expect(1 - DartboardRings.doubleInner, greaterThan(3 * real));
  });
}
