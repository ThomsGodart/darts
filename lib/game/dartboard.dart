import 'dart:math';

import 'package:flutter/material.dart';

import '../session/session.dart';
import '../theme/darts_space.dart';
import '../theme/darts_tokens.dart';
import 'dartboard_geometry.dart';

/// Enters a dart by touching where it landed on a drawn board. The spot
/// under the finger lights up and is named while the finger is down;
/// lifting it there enters the dart, sliding off the board first enters
/// nothing.
class Dartboard extends StatefulWidget {
  const Dartboard({super.key, required this.onDart});

  final ValueChanged<Dart> onDart;

  /// The board is never drawn wider: past this it only pushes the scores
  /// away.
  static const maxSide = 340.0;

  @override
  State<Dartboard> createState() => _DartboardState();
}

class _DartboardState extends State<Dartboard> {
  /// The dart under the finger; null when it is up or off the board.
  Dart? _aimed;

  /// Whether the finger is in the upper half: the name of the dart then
  /// shows at the bottom, clear of the hand.
  bool _aimedHigh = false;

  void _aim(Offset position, double side) {
    final dart = dartAt(dx: position.dx, dy: position.dy, side: side);
    final high = position.dy < side / 2;
    if (dart == _aimed && high == _aimedHigh) return;
    setState(() {
      _aimed = dart;
      _aimedHigh = high;
    });
  }

  void _release() {
    final dart = _aimed;
    if (dart == null) return;
    setState(() => _aimed = null);
    widget.onDart(dart);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<DartsTokens>()!;
    final aimed = _aimed;
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = min(constraints.maxWidth, Dartboard.maxSide);
        return Semantics(
          label: 'Cible : touchez l’endroit où la fléchette est arrivée',
          child: SizedBox.square(
            key: const Key('dartboard'),
            dimension: side,
            child: Listener(
              onPointerDown: (event) => _aim(event.localPosition, side),
              onPointerMove: (event) => _aim(event.localPosition, side),
              onPointerUp: (_) => _release(),
              onPointerCancel: (_) => setState(() => _aimed = null),
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size.square(side),
                    painter: _BoardPainter(
                      aimed: aimed,
                      scheme: theme.colorScheme,
                      highlight: tokens.activePlayer,
                      onHighlight: tokens.onActivePlayer,
                      numberStyle: theme.textTheme.labelLarge!,
                    ),
                  ),
                  if (aimed != null)
                    Align(
                      alignment: _aimedHigh
                          ? Alignment.bottomCenter
                          : Alignment.topCenter,
                      child: IgnorePointer(
                        child: Container(
                          key: const Key('dartboard-aimed'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: DartsSpace.lg,
                            vertical: DartsSpace.xs,
                          ),
                          decoration: BoxDecoration(
                            color: tokens.activePlayer,
                            borderRadius: BorderRadius.circular(DartsSpace.xl),
                          ),
                          child: Text(
                            aimed.notation,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: tokens.onActivePlayer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({
    required this.aimed,
    required this.scheme,
    required this.highlight,
    required this.onHighlight,
    required this.numberStyle,
  });

  final Dart? aimed;
  final ColorScheme scheme;

  /// What the spot under the finger is filled with, and what reads on it.
  final Color highlight;
  final Color onHighlight;
  final TextStyle numberStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(radius, radius);

    /// The part of a number between two rings, or a whole ring when
    /// [sweep] is a full turn.
    void band(
      double inner,
      double outer,
      double start,
      double sweep,
      Color color,
    ) {
      final path = Path()
        ..addArc(
          Rect.fromCircle(center: center, radius: outer * radius),
          start,
          sweep,
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: max(inner, 0.001) * radius),
          start + sweep,
          -sweep,
          false,
        )
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }

    // As on a real board: singles alternate dark and light, rings red
    // and green, in the theme's own colours.
    final singles = [
      scheme.surfaceContainerLowest,
      scheme.surfaceContainerHigh,
    ];
    final rings = [scheme.error, scheme.primary];

    for (final (i, number) in boardNumbers.indexed) {
      final start = -pi / 2 - sectorSweep / 2 + i * sectorSweep;
      Color colorOf(int multiplier, List<Color> colors) =>
          aimed?.sector == number && aimed?.multiplier == multiplier
          ? highlight
          : colors[i.isEven ? 0 : 1];

      band(
        DartboardRings.doubleInner,
        1,
        start,
        sectorSweep,
        colorOf(2, rings),
      );
      band(
        DartboardRings.trebleOuter,
        DartboardRings.doubleInner,
        start,
        sectorSweep,
        colorOf(1, singles),
      );
      band(
        DartboardRings.trebleInner,
        DartboardRings.trebleOuter,
        start,
        sectorSweep,
        colorOf(3, rings),
      );
      band(
        DartboardRings.outerBull,
        DartboardRings.trebleInner,
        start,
        sectorSweep,
        colorOf(1, singles),
      );

      // The number, in the outer single: the board has no rim to put it on.
      final middle = start + sectorSweep / 2;
      final at = (DartboardRings.trebleOuter + DartboardRings.doubleInner) / 2;
      final label = TextPainter(
        text: TextSpan(
          text: '$number',
          style: numberStyle.copyWith(
            color: aimed == Dart.single(number)
                ? onHighlight
                : scheme.onSurface,
            fontSize: radius * 0.11,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(
        canvas,
        center +
            Offset(cos(middle), sin(middle)) * (at * radius) -
            Offset(label.width / 2, label.height / 2),
      );
    }

    canvas
      ..drawCircle(
        center,
        DartboardRings.outerBull * radius,
        Paint()..color = aimed == Dart.outerBull ? highlight : scheme.primary,
      )
      ..drawCircle(
        center,
        DartboardRings.bull * radius,
        Paint()..color = aimed == Dart.bull ? highlight : scheme.error,
      );

    // Thin lines keep neighbours of the same colour apart.
    final line = Paint()
      ..color = scheme.outlineVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < boardNumbers.length; i++) {
      final angle = -pi / 2 - sectorSweep / 2 + i * sectorSweep;
      final direction = Offset(cos(angle), sin(angle));
      canvas.drawLine(
        center + direction * (DartboardRings.outerBull * radius),
        center + direction * radius,
        line,
      );
    }
    for (final ring in [
      DartboardRings.bull,
      DartboardRings.outerBull,
      DartboardRings.trebleInner,
      DartboardRings.trebleOuter,
      DartboardRings.doubleInner,
      1.0,
    ]) {
      canvas.drawCircle(center, ring * radius, line);
    }
  }

  @override
  bool shouldRepaint(_BoardPainter old) =>
      old.aimed != aimed ||
      old.scheme != scheme ||
      old.highlight != highlight ||
      old.onHighlight != onHighlight ||
      old.numberStyle != numberStyle;
}
