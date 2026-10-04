import 'dart:math';

import '../session/session.dart';

/// The numbers of a dartboard, clockwise from the top.
const boardNumbers = [
  20, 1, 18, 4, 13, 6, 10, 15, 2, 17, //
  3, 19, 7, 16, 8, 11, 14, 9, 12, 5,
];

/// Where the rings of the on-screen board sit, as fractions of its
/// radius. Not a real board's: the bull, the treble and the double are
/// several times wider, so that a finger can land in them.
abstract final class DartboardRings {
  static const bull = 0.11;
  static const outerBull = 0.22;
  static const trebleInner = 0.47;
  static const trebleOuter = 0.64;
  static const doubleInner = 0.82;
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
