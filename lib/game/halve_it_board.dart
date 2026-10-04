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

/// The rings of [target] that count, and a miss.
class HalveItInput extends StatelessWidget {
  const HalveItInput({
    super.key,
    required this.target,
    required this.dartsInVisit,
    required this.onDart,
    required this.onEndVisit,
    this.onUndo,
  });

  final HalveItTarget target;
  final List<Dart> dartsInVisit;
  final ValueChanged<Dart> onDart;
  final VoidCallback onEndVisit;
  final VoidCallback? onUndo;

  List<Dart> get _darts => switch ((target.sector, target.multiplier)) {
    (Dart.bullSector, _) => const [Dart.outerBull, Dart.bull],
    (final sector, 2) => [Dart.double(sector)],
    (final sector, 3) => [Dart.treble(sector)],
    (final sector, _) => [
      Dart.single(sector),
      Dart.double(sector),
      Dart.treble(sector),
    ],
  };

  @override
  Widget build(BuildContext context) => InputPane(
    dartsInVisit: dartsInVisit,
    onUndo: onUndo,
    onEndVisit: onEndVisit,
    children: [
      Row(
        children: [
          for (final dart in _darts)
            PadKey(
              // "S20" rather than "20": the ring is what is being chosen.
              label: dart.multiplier == 1 && dart.sector != Dart.bullSector
                  ? 'S${dart.sector}'
                  : dart.notation,
              onTap: () => onDart(dart),
            ),
        ],
      ),
      Row(
        children: [PadKey(label: 'Raté', onTap: () => onDart(Dart.miss))],
      ),
    ],
  );
}
