import 'package:flutter/material.dart';

import '../theme/darts_space.dart';

/// One player's line on a [ScoreList].
typedef ScoreLine = ({String name, String value, bool isActive});

/// The board of a game that is a target and a score per player: what
/// everyone is throwing at, then the players in throwing order.
class ScoreList extends StatelessWidget {
  const ScoreList({
    super.key,
    required this.title,
    this.hint,
    required this.lines,
  });

  /// What is being thrown at, e.g. "Cible D7".
  final String title;

  /// The rule worth recalling under the title.
  final String? hint;
  final List<ScoreLine> lines;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final hint = this.hint;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DartsSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            key: const Key('score-list-title'),
            textAlign: TextAlign.center,
            style: textTheme.displaySmall,
          ),
          if (hint != null) ...[
            const SizedBox(height: DartsSpace.xs),
            Text(
              hint,
              key: const Key('score-list-hint'),
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: DartsSpace.lg),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: DartsSpace.xs),
              child: Row(
                children: [
                  if (line.isActive)
                    Icon(Icons.play_arrow, color: colors.primary)
                  else
                    const SizedBox(width: DartsSpace.xl),
                  Expanded(
                    child: Text(
                      line.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: line.isActive
                          ? textTheme.headlineSmall
                          : textTheme.titleLarge,
                    ),
                  ),
                  Text(line.value, style: textTheme.headlineMedium),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
