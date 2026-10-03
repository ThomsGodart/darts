import 'package:flutter/material.dart';

import '../theme/darts_space.dart';
import '../session/session.dart';
import '../theme/darts_tokens.dart';
import '../ui/average_label.dart';
import '../ui/game_labels.dart';
import 'input_pane.dart';

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
///
/// With [onDart], darts are entered on the board: the numbers sit in the
/// middle, between the players, as single / double / treble keys.
class CricketBoard extends StatelessWidget {
  const CricketBoard({super.key, required this.game, this.onDart});

  final CricketGame game;

  /// Takes a dart tapped on the board; null when darts are entered
  /// elsewhere, the numbers then being plain labels in the first column.
  final ValueChanged<Dart>? onDart;

  /// Column of the numbers: first, or in the middle when they are keys.
  int get _labelColumn => onDart == null ? 0 : (game.scores.length + 1) ~/ 2;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<DartsTokens>()!;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      key: const Key('cricket-board'),
      padding: const EdgeInsets.all(DartsSpace.sm),
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
          const SizedBox(height: DartsSpace.xs),
          Table(
            // A new table when the columns change: next game, other players.
            key: ValueKey(game.scores.length),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: {_labelColumn: const IntrinsicColumnWidth()},
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
                  label: switch (onDart) {
                    final onDart? => _NumberKeys(
                      number: number,
                      // A dead number scores nothing: enter it as a miss.
                      onDart: game.isDead(number) ? null : onDart,
                    ),
                    null => Text(
                      number == Dart.bullSector ? 'Bull' : '$number',
                      style: textTheme.titleLarge?.copyWith(
                        color: game.isDead(number) ? tokens.cricketDead : null,
                        decoration: game.isDead(number)
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  },
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

  /// A board row: a label and one cell per player, the active player's
  /// column highlighted.
  TableRow _row({
    required Widget label,
    required Widget Function(CricketScore) cellOf,
    required DartsTokens tokens,
  }) {
    final cells = <Widget>[
      for (final (i, score) in game.scores.indexed)
        Container(
          color: i == game.activeIndex ? tokens.cricketActiveColumn : null,
          padding: const EdgeInsets.symmetric(
            vertical: DartsSpace.xs,
            horizontal: DartsSpace.xxs,
          ),
          alignment: Alignment.center,
          child: cellOf(score),
        ),
    ];
    cells.insert(
      _labelColumn,
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: DartsSpace.sm),
        child: label,
      ),
    );
    return TableRow(children: cells);
  }
}

/// Single, double and treble keys of one cricket number; the bull has no
/// treble. Disabled without [onDart].
class _NumberKeys extends StatelessWidget {
  const _NumberKeys({required this.number, required this.onDart});

  final int number;
  final ValueChanged<Dart>? onDart;

  @override
  Widget build(BuildContext context) {
    final onDart = this.onDart;
    final keys = number == Dart.bullSector
        ? [('Bull', Dart.outerBull), ('D', Dart.bull)]
        : [
            ('$number', Dart.single(number)),
            ('D', Dart.double(number)),
            ('T', Dart.treble(number)),
          ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (label, dart) in keys)
          Padding(
            padding: const EdgeInsets.all(DartsSpace.xxs),
            child: SizedBox(
              width: DartsSpace.tap,
              height: DartsSpace.tap,
              child: FilledButton.tonal(
                key: ValueKey('board-key-${dart.notation}'),
                onPressed: onDart == null ? null : () => onDart(dart),
                style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          ),
        // Keeps the bull's keys under the single and double columns.
        if (keys.length < 3)
          const SizedBox(width: DartsSpace.tap + 2 * DartsSpace.xxs),
      ],
    );
  }
}

/// Input pane of a cricket game entered on the board: what the keys of
/// the board cannot say.
class CricketBoardInput extends StatelessWidget {
  const CricketBoardInput({
    super.key,
    required this.dartsInVisit,
    required this.onDart,
    required this.onEndVisit,
    required this.onUndo,
  });

  final List<Dart> dartsInVisit;
  final ValueChanged<Dart> onDart;
  final VoidCallback onEndVisit;

  /// Takes back the latest dart; null when there is nothing to undo.
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) => InputPane(
    dartsInVisit: dartsInVisit,
    onUndo: onUndo,
    onEndVisit: onEndVisit,
    children: [
      Row(
        children: [PadKey(label: 'Raté', onTap: () => onDart(Dart.miss))],
      ),
    ],
  );
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
