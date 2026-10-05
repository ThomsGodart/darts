import 'dart:math';

import '../session/session.dart';

/// The numbers of a dartboard, clockwise from the top.
const boardNumbers = [
  20, 1, 18, 4, 13, 6, 10, 15, 2, 17, //
  3, 19, 7, 16, 8, 11, 14, 9, 12, 5,
];

/// Where the rings of the on-screen board sit, as fractions of its
/// radius. Close to a real board's, so that players recognise where they
/// touch: the bull, the treble and the double are only twice as wide as
/// the real ones, which leaves them thin under a finger — the name of the
/// spot shown while the finger is down is what makes them usable.
abstract final class DartboardRings {
  static const bull = 0.075;
  static const outerBull = 0.16;
  static const trebleInner = 0.56;
  static const trebleOuter = 0.655;
  static const doubleInner = 0.905;
}

/// The angle each number spans, in radians.
const sectorSweep = 2 * pi / 20;

/// The dart thrown at ([dx], [dy]) of a board drawn in a square of
/// [side]; null past the edge of the board.
Dart? dartAt({required double dx, required double dy, required double side}) {
  final radius = side / 2;
  final x = dx - radius;
  final y = dy - radius;
  final distance = sqrt(x * x + y * y) / radius;
  if (distance > 1) return null;
  if (distance <= DartboardRings.bull) return Dart.bull;
  if (distance <= DartboardRings.outerBull) return Dart.outerBull;

  // Clockwise from the top, shifted half a number so that 20 straddles it.
  final angle = (atan2(x, -y) + sectorSweep / 2) % (2 * pi);
  final number = boardNumbers[(angle / sectorSweep).floor() % 20];
  if (distance >= DartboardRings.doubleInner) return Dart.double(number);
  if (distance >= DartboardRings.trebleInner &&
      distance <= DartboardRings.trebleOuter) {
    return Dart.treble(number);
  }
  return Dart.single(number);
}
