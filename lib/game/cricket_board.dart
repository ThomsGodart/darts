import 'package:flutter/material.dart';

import '../session/session.dart';
import '../theme/darts_tokens.dart';
import '../ui/average_label.dart';

/// "/", "X" or "Ⓧ" for 1, 2 or 3 marks; empty for none.
String markSymbol(int marks) => switch (marks) {
  0 => '',
  1 => '/',
  2 => 'X',
  _ => 'Ⓧ',
};

/// Cricket scoreboard: a row per number (20 at the top, the bull last), a
/// column per player, points underneath.
class CricketBoard extends StatelessWidget {
  const CricketBoard({super.key, required this.game});

  final CricketGame game;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<DartsTokens>()!;
    final textTheme = Theme.of(context).textTheme;
    final active = game.activeIndex;

    Widget cell(int column, Widget child) => Container(
      color: column == active ? tokens.activePlayer : null,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      alignment: Alignment.center,
      child: child,
    );

    TextStyle onColumn(int column, TextStyle? base) =>
        (base ?? const TextStyle()).copyWith(
          color: column == active ? tokens.onActivePlayer : null,
        );

    return SingleChildScrollView(
      key: const Key('cricket-board'),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Text(
            switch (game.config.variant) {
              CricketVariant.standard => 'Cricket · le plus de points gagne',
              CricketVariant.cutThroat =>
                'Cut-Throat · le moins de points gagne',
            },
            key: const Key('cricket-variant'),
            style: textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          _table(game, cell, onColumn, textTheme),
        ],
      ),
    );
  }

  Widget _table(
    CricketGame game,
    Widget Function(int, Widget) cell,
    TextStyle Function(int, TextStyle?) onColumn,
    TextTheme textTheme,
  ) {
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {0: IntrinsicColumnWidth()},
      children: [
        TableRow(
          children: [
            const SizedBox.shrink(),
            for (final (i, score) in game.scores.indexed)
              cell(
                i,
                Text(
                  score.player.name,
                  overflow: TextOverflow.ellipsis,
                  style: onColumn(i, textTheme.titleMedium),
                ),
              ),
          ],
        ),
        for (final number in cricketNumbers)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  number == Dart.bullSector ? 'Bull' : '$number',
                  style: textTheme.titleLarge?.copyWith(
                    decoration: game.isDead(number)
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
              for (final (i, score) in game.scores.indexed)
                cell(
                  i,
                  Text(
                    markSymbol(score.marksOn(number)),
                    style: onColumn(i, textTheme.headlineSmall),
                  ),
                ),
            ],
          ),
        TableRow(
          children: [
            const SizedBox.shrink(),
            for (final (i, score) in game.scores.indexed)
              cell(
                i,
                Text(
                  '${score.points}',
                  style: onColumn(
                    i,
                    textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('MPR', style: textTheme.labelLarge),
            ),
            for (final (i, score) in game.scores.indexed)
              cell(
                i,
                Text(
                  averageLabel(game.marksPerRound(score.player)),
                  style: onColumn(i, textTheme.labelLarge),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
