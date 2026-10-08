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
  static const _labelWidth = 72.0;

  /// How much wider the thrower's column is when columns share the width.
  static const _activeFlex = 5;
  static const _idleFlex = 4;

  /// How much larger the thrower's name, points and marks read when there
  /// is room to grow.
  static const _activeScale = 1.18;

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
    final grid = Theme.of(context).colorScheme.outlineVariant;
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
                      grid: grid,
                      marksWidth: marksWidth,
                      label: const SizedBox.shrink(),
                      cellOf: (score, {required active}) => FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          score.player.name,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                          // With keys beside the marks, names stay compact;
                          // without, they fill the column — the thrower
                          // a notch larger when the columns can grow.
                          style:
                              (showKeys
                                      ? textTheme.titleSmall
                                      : active
                                      ? textTheme.headlineMedium
                                      : textTheme.headlineSmall)
                                  ?.copyWith(
                                    fontWeight: active
                                        ? FontWeight.w900
                                        : FontWeight.w600,
                                    decoration: active
                                        ? TextDecoration.underline
                                        : null,
                                  ),
                        ),
                      ),
                    ),
                    _row(
                      tokens: tokens,
                      grid: grid,
                      marksWidth: marksWidth,
                      label: const SizedBox.shrink(),
                      cellOf: (score, {required active}) => FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${score.points}',
                          style: TextStyle(
                            fontSize:
                                tokens.cricketPointsFontSize *
                                (active && marksWidth == null
                                    ? _activeScale
                                    : 1),
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
                          grid,
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
    Color grid,
  ) {
    final isDead = game.isDead(number);
    return _row(
      tokens: tokens,
      grid: grid,
      marksWidth: marksWidth,
      fillsHeight: true,
      // A number nobody scores on any more: its row goes dark, the marks
      // staying full so that it never reads as not played.
      color: isDead ? tokens.cricketDeadRow : null,
      label: showKeys
          ? CricketNumberKeys(
              number: number,
              isDead: isDead,
              onDart: isDead ? null : onDart,
            )
          : Text(
              number == Dart.bullSector ? 'Bull' : '$number',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: isDead ? tokens.cricketDead : null,
                decoration: isDead ? TextDecoration.lineThrough : null,
              ),
            ),
      cellOf: (score, {required active}) => _Mark(
        marks: score.marksOn(number),
        isDead: isDead,
        tokens: tokens,
        scale: active && marksWidth == null ? _activeScale : 1,
      ),
    );
  }

  Widget _row({
    required Widget label,
    required Widget Function(CricketScore score, {required bool active})
    cellOf,
    required DartsTokens tokens,
    required Color grid,
    Color? color,
    bool fillsHeight = false,
    double? marksWidth,
  }) {
    // Half-width so neighbouring cells share a single fine line.
    final line = BorderSide(color: grid, width: 0.5);
    Widget cell({
      required Widget child,
      required bool active,
      AlignmentGeometry alignment = Alignment.center,
    }) => Container(
      decoration: BoxDecoration(
        color: active ? tokens.cricketActiveColumn : null,
        border: Border.fromBorderSide(line),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: DartsSpace.xs,
        horizontal: DartsSpace.xxs,
      ),
      alignment: alignment,
      child: child,
    );

    // With keys, the players' columns are as wide as marks need and the
    // keys take the rest; without, the players share what the labels
    // leave — the thrower a little more of that share.
    Widget column({required Widget child, required bool active}) {
      final boxed = cell(child: child, active: active);
      if (marksWidth != null) {
        return SizedBox(width: marksWidth, child: boxed);
      }
      return Expanded(
        flex: active ? _activeFlex : _idleFlex,
        child: boxed,
      );
    }

    final slots = <({Widget child, bool active, bool isLabel})>[
      for (final (i, score) in game.scores.indexed)
        (
          child: cellOf(score, active: i == game.activeIndex),
          active: i == game.activeIndex,
          isLabel: false,
        ),
    ];
    slots.insert(_labelColumn, (child: label, active: false, isLabel: true));

    final cells = <Widget>[
      for (final slot in slots)
        if (slot.isLabel)
          marksWidth == null
              ? SizedBox(
                  width: _labelWidth,
                  child: cell(
                    child: slot.child,
                    active: false,
                    alignment: AlignmentDirectional.centerStart,
                  ),
                )
              : Expanded(
                  child: cell(
                    child: slot.child,
                    active: false,
                    alignment: AlignmentDirectional.centerStart,
                  ),
                )
        else
          column(child: slot.child, active: slot.active),
    ];
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
class CricketNumberKeys extends StatelessWidget {
  const CricketNumberKeys({
    super.key,
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
                                  ? textTheme.headlineSmall
                                  : textTheme.titleMedium)
                              ?.copyWith(
                                fontWeight: dart.multiplier == 1 || isBull
                                    ? FontWeight.w800
                                    : FontWeight.w600,
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

/// The input pane of a cricket game entered on its board: the visit so
/// far and the actions. With [showKeys], the D/S/T grid sits here too —
/// used when the shell splits so the marks fill the state pane.
class CricketBoardInput extends StatelessWidget {
  const CricketBoardInput({
    super.key,
    required this.game,
    required this.dartsInVisit,
    required this.onDart,
    required this.onEndVisit,
    required this.onUndo,
    this.showKeys = false,
  });

  final CricketGame game;
  final List<Dart> dartsInVisit;
  final ValueChanged<Dart> onDart;
  final VoidCallback onEndVisit;
  final VoidCallback? onUndo;

  /// Whether the number keys are in this pane rather than on the board.
  final bool showKeys;

  static const _keyRowHeight = 44.0;

  @override
  Widget build(BuildContext context) {
    final visitOver = game.visitIsOver;
    return InputPane(
      dartsInVisit: dartsInVisit,
      onUndo: onUndo,
      onEndVisit: onEndVisit,
      visitIsOver: visitOver,
      children: [
        if (showKeys)
          for (final number in cricketNumbers)
            SizedBox(
              height: _keyRowHeight,
              child: CricketNumberKeys(
                number: number,
                isDead: game.isDead(number),
                onDart: visitOver || game.isDead(number) ? null : onDart,
              ),
            ),
      ],
    );
  }
}

/// The marks of one player on one number: "/", "X", then the X in a ring
/// once closed — on a tinted disc, so that a closed number is told from
/// afar from one with two marks.
class _Mark extends StatelessWidget {
  const _Mark({
    required this.marks,
    required this.isDead,
    required this.tokens,
    this.scale = 1,
  });

  final int marks;
  final bool isDead;
  final DartsTokens tokens;

  /// Grows the mark when the thrower's column has room.
  final double scale;

  @override
  Widget build(BuildContext context) {
    if (marks == 0) {
      return Semantics(label: 'aucune marque', child: const SizedBox.shrink());
    }
    final closed = marks >= marksToClose;
    final fontSize = tokens.cricketMarkFontSize * scale;
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
