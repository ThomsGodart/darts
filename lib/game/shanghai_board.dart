import 'package:flutter/material.dart';

import '../theme/darts_space.dart';
import '../session/session.dart';

/// Scores and the number of the round for a Shanghai game.
class ShanghaiBoard extends StatelessWidget {
  const ShanghaiBoard({super.key, required this.game});

  final ShanghaiGame game;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(DartsSpace.lg),
      child: Column(
        key: const Key('shanghai-board'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Chiffre ${game.currentNumber}',
            key: const Key('shanghai-number'),
            textAlign: TextAlign.center,
            style: textTheme.displaySmall,
          ),
          const SizedBox(height: DartsSpace.lg),
          for (final (i, score) in game.scores.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  if (i == game.activeIndex)
                    Icon(Icons.play_arrow, color: colors.primary)
                  else
                    const SizedBox(width: DartsSpace.xl),
                  Expanded(
                    child: Text(
                      score.player.name,
                      style: i == game.activeIndex
                          ? textTheme.headlineSmall
                          : textTheme.titleLarge,
                    ),
                  ),
                  Text('${score.points}', style: textTheme.headlineMedium),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// S / D / T of [number], miss, and end-of-visit.
class ShanghaiInput extends StatelessWidget {
  const ShanghaiInput({
    super.key,
    required this.number,
    required this.dartsInVisit,
    required this.onDart,
    required this.onEndVisit,
    this.onUndo,
  });

  final int number;
  final List<Dart> dartsInVisit;
  final ValueChanged<Dart> onDart;
  final VoidCallback onEndVisit;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(DartsSpace.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              [
                for (var i = 0; i < dartsPerVisit; i++)
                  dartsInVisit.elementAtOrNull(i)?.notation ?? '–',
              ].join('  ·  '),
              key: const Key('darts-in-visit'),
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: DartsSpace.sm),
            Row(
              children: [
                _Key(
                  label: 'S$number',
                  onTap: () => onDart(Dart.single(number)),
                ),
                _Key(
                  label: 'D$number',
                  onTap: () => onDart(Dart.double(number)),
                ),
                _Key(
                  label: 'T$number',
                  onTap: () => onDart(Dart.treble(number)),
                ),
              ],
            ),
            Row(
              children: [
                _Key(label: 'Raté', onTap: () => onDart(Dart.miss)),
                _Key(label: 'Fin de tour', onTap: onEndVisit),
              ],
            ),
            const SizedBox(height: DartsSpace.xs),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onUndo,
                icon: const Icon(Icons.undo),
                label: const Text('Annuler la saisie'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(DartsSpace.xxs),
        child: SizedBox(
          height: 52,
          child: FilledButton.tonal(onPressed: onTap, child: Text(label)),
        ),
      ),
    );
  }
}
