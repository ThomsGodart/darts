import 'package:flutter/material.dart';

import '../session/session.dart';
import '../theme/darts_tokens.dart';
import '../ui/average_label.dart';
import '../ui/game_labels.dart';

/// "/", "X" or "Ⓧ" for 1, 2 or 3 marks; empty for none.
String markSymbol(int marks) => switch (marks) {
  0 => '',
  1 => '/',
  2 => 'X',
  _ => 'Ⓧ',
};

/// Cricket scoreboard: a row per number (20 at the top, the bull last), a
/// column per player, points and MPR underneath. Player columns share the
/// width, so up to eight players fit a phone without scrolling sideways.
class CricketBoard extends StatelessWidget {
  const CricketBoard({super.key, required this.game});

  final CricketGame game;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<DartsTokens>()!;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      key: const Key('cricket-board'),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Text(
            '${variantLabel(game.config.variant)} · '
            '${switch (game.config.variant) {
              CricketVariant.standard => 'le plus de points gagne',
              CricketVariant.cutThroat => 'le moins de points gagne',
            }}',
            key: const Key('cricket-variant'),
            style: textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {0: IntrinsicColumnWidth()},
            defaultColumnWidth: const FlexColumnWidth(),
            children: [
              _row(
                label: const SizedBox.shrink(),
                cellOf: (score) => Text(
                  score.player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall,
                ),
                tokens: tokens,
              ),
              for (final number in cricketNumbers)
                _row(
                  label: Text(
                    number == Dart.bullSector ? 'Bull' : '$number',
                    style: textTheme.titleLarge?.copyWith(
                      color: game.isDead(number) ? tokens.cricketDead : null,
                      decoration: game.isDead(number)
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  cellOf: (score) => _Mark(
                    marks: score.marksOn(number),
                    color: game.isDead(number)
                        ? tokens.cricketDead
                        : score.isClosed(number)
                        ? tokens.cricketClosed
                        : tokens.cricketMark,
                    fontSize: tokens.cricketMarkFontSize,
                  ),
                  tokens: tokens,
                ),
              _row(
                label: const SizedBox.shrink(),
                cellOf: (score) => FittedBox(
                  child: Text(
                    '${score.points}',
                    style: TextStyle(
                      fontSize: tokens.cricketPointsFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                tokens: tokens,
              ),
              _row(
                label: Text('MPR', style: textTheme.labelLarge),
                cellOf: (score) => Text(
                  averageLabel(game.marksPerRound(score.player)),
                  style: textTheme.labelLarge,
                ),
                tokens: tokens,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// A board row: a label, then one cell per player, the active player's
  /// column highlighted.
  TableRow _row({
    required Widget label,
    required Widget Function(CricketScore) cellOf,
    required DartsTokens tokens,
  }) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: label,
        ),
        for (final (i, score) in game.scores.indexed)
          Container(
            color: i == game.activeIndex ? tokens.cricketActiveColumn : null,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            alignment: Alignment.center,
            child: cellOf(score),
          ),
      ],
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({
    required this.marks,
    required this.color,
    required this.fontSize,
  });

  final int marks;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: fontSize * 1.2,
    child: FittedBox(
      child: Text(
        markSymbol(marks),
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
    ),
  );
}
