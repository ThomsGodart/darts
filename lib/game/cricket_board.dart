import 'package:flutter/material.dart';

import '../theme/darts_space.dart';
import '../session/session.dart';
import '../theme/darts_tokens.dart';
import 'input_pane.dart';

/// "/", "X" or "Ⓧ" for 1, 2 or 3 marks; empty for none. The board draws
/// the last one itself.
String markSymbol(int marks) => switch (marks) {
  0 => '',
  1 => '/',
  2 => 'X',
  _ => 'Ⓧ',
};

/// Cricket scoreboard: the round being played, then a column per player
/// with their points, and a row per number (20 at the top, the bull
/// last). The rows share all the height there is, to be read from the
/// oche; player columns share the width, so up to eight players fit a
/// phone without scrolling sideways.
///
/// With [showKeys], darts are entered on the board: the numbers sit in
/// the middle, between the players, as double / single / treble keys.
class CricketBoard extends StatelessWidget {
  const CricketBoard({
    super.key,
    required this.game,
    this.onDart,
    bool? showKeys,
  }) : showKeys = showKeys ?? onDart != null;

  final CricketGame game;

  /// Takes a dart tapped on the board; null turns the keys off.
  final ValueChanged<Dart>? onDart;

  /// Whether the numbers are keys; plain labels in the first column
  /// otherwise, the darts being entered elsewhere.
  final bool showKeys;

  /// Column of the numbers: first, or in the middle when they are keys.
  int get _labelColumn => showKeys ? (game.scores.length + 1) ~/ 2 : 0;

  /// The least the three keys of a number take, and the most a player's
  /// column is given when the numbers are keys: marks need little room,
  /// the rest goes to the keys.
  static const _minKeysWidth = 3 * (DartsSpace.tap + 2 * DartsSpace.xxs);
  static const _maxMarksWidth = 76.0;
  static const _labelWidth = 64.0;

  /// The width of a player's column in a board [width] wide, when the
  /// numbers are keys.
  double _marksWidth(double width) {
    final shared = (width - _minKeysWidth) / game.scores.length;
    return shared.clamp(0.0, _maxMarksWidth);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<DartsTokens>()!;
    final textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final marksWidth = showKeys && constraints.hasBoundedWidth
            ? _marksWidth(constraints.maxWidth - 2 * DartsSpace.sm)
            : null;
        return SingleChildScrollView(
          key: const Key('cricket-board'),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.hasBoundedHeight
                  ? constraints.maxHeight
                  : 0,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(DartsSpace.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Round ${game.round}',
                      key: const Key('cricket-round'),
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: DartsSpace.xs),
                    _row(
                      tokens: tokens,
                      marksWidth: marksWidth,
                      label: const SizedBox.shrink(),
                      cellOf: (score) => Text(
                        score.player.name,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: score.player.id == game.activePlayer.id
                              ? FontWeight.w900
                              : null,
                          decoration: score.player.id == game.activePlayer.id
                              ? TextDecoration.underline
                              : null,
                        ),
                      ),
                    ),
                    _row(
                      tokens: tokens,
                      marksWidth: marksWidth,
                      label: const SizedBox.shrink(),
                      cellOf: (score) => FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${score.points}',
                          style: TextStyle(
                            fontSize: tokens.cricketPointsFontSize,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                    for (final number in cricketNumbers)
                      Expanded(
                        child: _numberRow(
                          number,
                          tokens,
                          textTheme,
                          marksWidth,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _numberRow(
    int number,
    DartsTokens tokens,
    TextTheme textTheme,
    double? marksWidth,
  ) {
    final isDead = game.isDead(number);
    return _row(
      tokens: tokens,
      marksWidth: marksWidth,
      fillsHeight: true,
      // A number nobody scores on any more: its row goes dark, the marks
      // staying full so that it never reads as not played.
      color: isDead ? tokens.cricketDeadRow : null,
      label: showKeys
          ? _NumberKeys(
              number: number,
              isDead: isDead,
              onDart: isDead ? null : onDart,
            )
          : Text(
              number == Dart.bullSector ? 'Bull' : '$number',
              style: textTheme.titleLarge?.copyWith(
                color: isDead ? tokens.cricketDead : null,
                decoration: isDead ? TextDecoration.lineThrough : null,
              ),
            ),
      cellOf: (score) =>
          _Mark(marks: score.marksOn(number), isDead: isDead, tokens: tokens),
    );
  }

  Widget _row({
    required Widget label,
    required Widget Function(CricketScore) cellOf,
    required DartsTokens tokens,
    Color? color,
    bool fillsHeight = false,
    double? marksWidth,
  }) {
    // With keys, the players' columns are as wide as marks need and the
    // keys take the rest; without, the players share what the labels
    // leave.
    Widget column(Widget child) => marksWidth == null
        ? Expanded(child: child)
        : SizedBox(width: marksWidth, child: child);
    final cells = <Widget>[
      for (final (i, score) in game.scores.indexed)
        column(
          Container(
            color: i == game.activeIndex ? tokens.cricketActiveColumn : null,
            padding: const EdgeInsets.symmetric(
              vertical: DartsSpace.xs,
              horizontal: DartsSpace.xxs,
            ),
            alignment: Alignment.center,
            child: cellOf(score),
          ),
        ),
    ];
    cells.insert(
      _labelColumn,
      marksWidth == null
          ? SizedBox(
              width: _labelWidth,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: label,
              ),
            )
          : Expanded(child: label),
    );
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: cells,
    );
    return ColoredBox(
      color: color ?? Colors.transparent,
      // A number row is given its height; the others take their cells'.
      child: fillsHeight ? row : IntrinsicHeight(child: row),
    );
  }
}

/// The keys of one cricket number as they sit on a real board's wire,
/// going out from the middle: double, single, treble. The bull has its
/// two rings, 50 and 25, and no treble: they share the row.
class _NumberKeys extends StatelessWidget {
  const _NumberKeys({
    required this.number,
    required this.isDead,
    required this.onDart,
  });

  final int number;
  final bool isDead;
  final ValueChanged<Dart>? onDart;

  static const _minKeyHeight = 28.0;

  @override
  Widget build(BuildContext context) {
    final onDart = this.onDart;
    final textTheme = Theme.of(context).textTheme;
    final isBull = number == Dart.bullSector;
    final keys = isBull
        ? [
            ('50', 'Bull, 50', Dart.bull),
            ('25', 'Bull extérieur, 25', Dart.outerBull),
          ]
        : [
            ('D', 'Double $number', Dart.double(number)),
            ('$number', 'Simple $number', Dart.single(number)),
            ('T', 'Triple $number', Dart.treble(number)),
          ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (label, spoken, dart) in keys)
          // The keys share the width the marks leave, the number itself —
          // the key hit most — taking a little more than its rings.
          Expanded(
            flex: dart.multiplier == 1 || isBull ? 5 : 4,
            child: Padding(
              padding: const EdgeInsets.all(DartsSpace.xxs),
              child: ConstrainedBox(
                // Shorter than a full tap target when the board is short
                // of height, as on a phone held sideways: all seven
                // numbers stay on screen.
                constraints: const BoxConstraints(minHeight: _minKeyHeight),
                child: FilledButton.tonal(
                  key: ValueKey('board-key-${dart.notation}'),
                  onPressed: onDart == null ? null : () => onDart(dart),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      semanticsLabel: spoken,
                      // The number itself is what the eye looks for.
                      style:
                          (dart.multiplier == 1 || isBull
                                  ? textTheme.titleLarge
                                  : textTheme.titleMedium)
                              ?.copyWith(
                                decoration: isDead
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The input pane of a cricket game entered on its board: the keys are on
/// the board, so this is the visit so far and the actions.
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
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) => InputPane(
    dartsInVisit: dartsInVisit,
    onUndo: onUndo,
    onEndVisit: onEndVisit,
    children: const [],
  );
}

/// The marks of one player on one number: "/", "X", then the X in a ring
/// once closed — on a tinted disc, so that a closed number is told from
/// afar from one with two marks.
class _Mark extends StatelessWidget {
  const _Mark({
    required this.marks,
    required this.isDead,
    required this.tokens,
  });

  final int marks;
  final bool isDead;
  final DartsTokens tokens;

  @override
  Widget build(BuildContext context) {
    if (marks == 0) {
      return Semantics(label: 'aucune marque', child: const SizedBox.shrink());
    }
    final closed = marks >= marksToClose;
    final fontSize = tokens.cricketMarkFontSize;
    final mark = Container(
      key: closed ? const Key('mark-closed') : null,
      padding: const EdgeInsets.all(DartsSpace.xs),
      decoration: closed
          ? BoxDecoration(
              shape: BoxShape.circle,
              color: tokens.cricketClosed.withValues(alpha: 0.28),
              border: Border.all(color: tokens.cricketClosed, width: 3),
            )
          : null,
      child: Text(
        closed ? 'X' : markSymbol(marks),
        semanticsLabel: switch (marks) {
          1 => '1 marque',
          _ when closed => 'fermé',
          _ => '$marks marques',
        },
        style: TextStyle(
          fontSize: fontSize,
          color: closed ? tokens.cricketClosed : tokens.cricketMark,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
    );
    // Fills the row whatever its height, up to twice its size at rest,
    // without asking for more than a short row has: only the box under
    // it counts when the board works out how tall its rows must be.
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(height: fontSize * 0.7),
          Positioned.fill(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: fontSize * 2.4),
                child: SizedBox.expand(
                  child: FittedBox(
                    child: Opacity(opacity: isDead ? 0.7 : 1, child: mark),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
