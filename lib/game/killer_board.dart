import 'package:flutter/material.dart';

import '../session/session.dart';
import '../theme/darts_space.dart';
import '../ui/game_stats.dart';
import 'input_pane.dart';

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
              padding: const EdgeInsets.symmetric(vertical: DartsSpace.xs),
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
                  Text(killerLivesLabel(score), style: textTheme.headlineSmall),
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
  Widget build(BuildContext context) => InputPane(
    onUndo: onUndo,
    children: [
      SectorGrid(
        labelOf: (sector) => '$sector',
        onSector: onAssign,
        isEnabled: (sector) => !taken.contains(sector),
      ),
    ],
  );
}

/// Doubles grid and miss for Killer play.
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
  Widget build(BuildContext context) => InputPane(
    dartsInVisit: dartsInVisit,
    onUndo: onUndo,
    onEndVisit: onEndVisit,
    children: [
      SectorGrid(
        labelOf: (sector) => 'D$sector',
        onSector: (sector) => onDart(Dart.double(sector)),
      ),
      Row(
        children: [PadKey(label: 'Raté', onTap: () => onDart(Dart.miss))],
      ),
    ],
  );
}
