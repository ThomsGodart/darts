import 'package:flutter/material.dart';

import '../theme/darts_space.dart';
import '../theme/darts_tokens.dart';

/// Briefly names the player who should take the phone, then fades out.
/// Purely visual: taps go through to the input underneath.
class TurnBanner extends StatelessWidget {
  const TurnBanner({super.key, required this.playerName, required this.onDone});

  final String playerName;
  final VoidCallback onDone;

  static const _duration = Duration(milliseconds: 1400);

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<DartsTokens>()!;
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1, end: 0),
        duration: _duration,
        // Fully visible most of the time, then a quick fade.
        curve: const Interval(0.7, 1),
        onEnd: onDone,
        builder: (context, opacity, child) =>
            Opacity(opacity: opacity, child: child),
        child: Container(
          key: const Key('turn-banner'),
          width: double.infinity,
          color: tokens.activePlayer,
          padding: const EdgeInsets.symmetric(vertical: DartsSpace.xl),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: DartsSpace.lg),
              child: Text(
                'À toi, $playerName !',
                textAlign: TextAlign.center,
                style: TextStyle(
                  // Same order of magnitude as the active remaining score,
                  // so the hand-off reads from the oche on a tablet too.
                  fontSize: tokens.remainingFontSize * 0.55,
                  color: tokens.onActivePlayer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
