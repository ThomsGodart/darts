import 'package:flutter/material.dart';

import '../session/session.dart';
import 'input_pane.dart';
import 'score_list.dart';

/// The target of the round and everyone's score in a Halve-It game.
class HalveItBoard extends StatelessWidget {
  const HalveItBoard({super.key, required this.game});

  final HalveItGame game;

  @override
  Widget build(BuildContext context) => ScoreList(
    key: const Key('halve-it-board'),
    title: 'Cible ${game.currentTarget.label}',
    hint: 'Une volée sans touche divise le score par 2',
    lines: [
      for (final (i, score) in game.scores.indexed)
        if (i == game.activeIndex && !game.isFinished)
          (
            name: score.player.name,
            value: '${game.activeLivePoints}',
            isActive: true,
          )
        else
          (
            name: score.player.name,
            // The halving just suffered stays in view until the next visit.
            value: score.wasHalved ? '÷2  ${score.points}' : '${score.points}',
            isActive: false,
          ),
    ],
  );
}

/// The rings of [target] that count.
List<DartKey> halveItKeys(HalveItTarget target) => switch ((
  target.sector,
  target.multiplier,
)) {
  (Dart.bullSector, _) => const [('25', Dart.outerBull), ('Bull', Dart.bull)],
  (final sector, 2) => [('D$sector', Dart.double(sector))],
  (final sector, 3) => [('T$sector', Dart.treble(sector))],
  (final sector, _) => ringKeys(sector),
};
