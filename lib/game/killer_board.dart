import 'package:flutter/material.dart';

import '../session/session.dart';
import '../theme/darts_space.dart';

/// Lives, numbers and Killer status.
class KillerBoard extends StatelessWidget {
  const KillerBoard({super.key, required this.game});

  final KillerGame game;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(DartsSpace.lg),
      child: Column(
        key: const Key('killer-board'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            game.phase == KillerPhase.assigning
                ? 'Attribution des chiffres'
                : 'Killer',
            key: const Key('killer-phase'),
            textAlign: TextAlign.center,
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: DartsSpace.md),
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
                      [
                        score.player.name,
                        if (score.number != null) '· ${score.number}',
                        if (score.isKiller) '· KILLER',
                        if (score.isOut) '· OUT',
                      ].join(' '),
                      style: i == game.activeIndex
                          ? textTheme.titleLarge
                          : textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    score.isOut ? 'OUT' : '${score.lives ?? 0}',
                    style: textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Pick a free sector 1–20 during Killer attribution.
class KillerAssignInput extends StatelessWidget {
  const KillerAssignInput({
    super.key,
    required this.taken,
    required this.onAssign,
    this.onUndo,
  });

  final Set<int> taken;
  final ValueChanged<int> onAssign;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(DartsSpace.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var row = 0; row < 4; row++)
              Row(
                children: [
                  for (
                    var sector = row * 5 + 1;
                    sector <= row * 5 + 5;
                    sector++
                  )
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(DartsSpace.xxs),
                        child: SizedBox(
                          height: DartsSpace.tap,
                          child: FilledButton.tonal(
                            onPressed: taken.contains(sector)
                                ? null
                                : () => onAssign(sector),
                            child: Text('$sector'),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            OutlinedButton.icon(
              onPressed: onUndo,
              icon: const Icon(Icons.undo),
              label: const Text('Annuler la saisie'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Doubles grid + miss + end of visit for Killer play.
class KillerPlayInput extends StatelessWidget {
  const KillerPlayInput({
    super.key,
    required this.dartsInVisit,
    required this.onDart,
    required this.onEndVisit,
    this.onUndo,
  });

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
            for (var row = 0; row < 4; row++)
              Row(
                children: [
                  for (
                    var sector = row * 5 + 1;
                    sector <= row * 5 + 5;
                    sector++
                  )
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(DartsSpace.xxs),
                        child: SizedBox(
                          height: DartsSpace.tap,
                          child: FilledButton.tonal(
                            onPressed: () => onDart(Dart.double(sector)),
                            child: Text('D$sector'),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(DartsSpace.xxs),
                    child: SizedBox(
                      height: DartsSpace.tap,
                      child: FilledButton.tonal(
                        onPressed: () => onDart(Dart.miss),
                        child: const Text('Raté'),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(DartsSpace.xxs),
                    child: SizedBox(
                      height: DartsSpace.tap,
                      child: FilledButton.tonal(
                        onPressed: onEndVisit,
                        child: const Text('Fin de tour'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            OutlinedButton.icon(
              onPressed: onUndo,
              icon: const Icon(Icons.undo),
              label: const Text('Annuler la saisie'),
            ),
          ],
        ),
      ),
    );
  }
}
