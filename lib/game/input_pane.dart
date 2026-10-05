import 'package:flutter/material.dart';

import '../session/session.dart';
import '../theme/darts_space.dart';

/// The pane a visit is entered in, whatever the game: the darts thrown so
/// far, the game's own keys, then what every visit offers — taking the
/// latest input back and ending the visit. A visit that has had its last
/// dart stays on screen, its keys off, until the players end it.
class InputPane extends StatelessWidget {
  const InputPane({
    super.key,
    this.header,
    this.dartsInVisit,
    required this.children,
    required this.onUndo,
    this.onEndVisit,
    this.secondaryAction,
    this.visitIsOver,
  });

  /// Whether the visit takes no more darts and waits to be ended; by
  /// default, once [dartsInVisit] is full.
  final bool? visitIsOver;

  /// Shown above everything else, e.g. a mode switch.
  final Widget? header;

  /// Darts of the visit in progress; null when no dart is being entered.
  final List<Dart>? dartsInVisit;

  /// The keys of the game.
  final List<Widget> children;

  /// Takes back the latest input; null when there is nothing to undo.
  final VoidCallback? onUndo;

  /// Ends the visit and passes the turn; null hides the option.
  final VoidCallback? onEndVisit;

  /// Sits next to the undo when the visit cannot be ended.
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final header = this.header;
    final dartsInVisit = this.dartsInVisit;
    final isOver = visitIsOver ?? (dartsInVisit?.length ?? 0) >= dartsPerVisit;
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final trailing = switch (onEndVisit) {
      // The key pressed most: the largest, and the only one left when
      // the visit is over.
      final onEndVisit? => FilledButton(
        key: const Key('end-visit'),
        onPressed: onEndVisit,
        child: Text(
          'Fin de tour',
          style: textTheme.titleMedium?.copyWith(color: colors.onPrimary),
        ),
      ),
      null => secondaryAction,
    };
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(DartsSpace.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (header != null) ...[
              header,
              const SizedBox(height: DartsSpace.sm),
            ],
            if (dartsInVisit != null) ...[
              Text(
                [
                  for (var i = 0; i < dartsPerVisit; i++)
                    dartsInVisit.elementAtOrNull(i)?.notation ?? '–',
                ].join('  ·  '),
                key: const Key('darts-in-visit'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: DartsSpace.sm),
            ],
            if (isOver)
              IgnorePointer(
                key: const Key('visit-over'),
                child: Opacity(
                  opacity: 0.35,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: children,
                  ),
                ),
              )
            else
              ...children,
            const SizedBox(height: DartsSpace.xs),
            SizedBox(
              height: DartsSpace.tap,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (trailing == null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onUndo,
                        icon: const Icon(Icons.undo),
                        label: const Text('Annuler la saisie'),
                      ),
                    )
                  else ...[
                    // Next to the key that ends the visit, the undo is
                    // its icon alone: the room goes to the keys.
                    Tooltip(
                      message: 'Annuler la saisie',
                      child: OutlinedButton(
                        key: const Key('undo'),
                        onPressed: onUndo,
                        child: const Icon(
                          Icons.undo,
                          semanticLabel: 'Annuler la saisie',
                        ),
                      ),
                    ),
                    const SizedBox(width: DartsSpace.sm),
                    Expanded(child: trailing),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One key of an input pane, sharing its row's width; disabled without
/// [onTap].
class PadKey extends StatelessWidget {
  const PadKey({
    super.key,
    required this.label,
    required this.onTap,
    this.emphasized = false,
    this.large = false,
  });

  final String label;
  final VoidCallback? onTap;

  /// Filled rather than tonal: the key that confirms.
  final bool emphasized;

  /// Larger label, for keys read at arm's length.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = FilledButton.styleFrom(padding: EdgeInsets.zero);
    // Shrinks rather than clips when the system text size is large.
    final child = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        label,
        // A filled key is the primary colour: its label takes the colour
        // that reads on it, not the surface's.
        style: (large ? textTheme.titleLarge : textTheme.titleMedium)?.copyWith(
          color: emphasized && onTap != null
              ? Theme.of(context).colorScheme.onPrimary
              : null,
        ),
      ),
    );
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(DartsSpace.xxs),
        child: SizedBox(
          height: DartsSpace.tap,
          child: emphasized
              ? FilledButton(onPressed: onTap, style: style, child: child)
              : FilledButton.tonal(
                  onPressed: onTap,
                  style: style,
                  child: child,
                ),
        ),
      ),
    );
  }
}

/// The sectors 1–20, five to a row.
class SectorGrid extends StatelessWidget {
  const SectorGrid({
    super.key,
    required this.labelOf,
    required this.onSector,
    this.isEnabled,
  });

  final String Function(int sector) labelOf;
  final ValueChanged<int> onSector;

  /// Sectors that can be tapped; all of them when null.
  final bool Function(int sector)? isEnabled;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var row = 0; row < 4; row++)
        Row(
          children: [
            for (var sector = row * 5 + 1; sector <= row * 5 + 5; sector++)
              PadKey(
                label: labelOf(sector),
                onTap: isEnabled?.call(sector) ?? true
                    ? () => onSector(sector)
                    : null,
              ),
          ],
        ),
    ],
  );
}

/// A key of a [DartKeysInput]: its label and the dart it enters.
typedef DartKey = (String label, Dart dart);

/// Single, double and treble of [number]: the keys of a game thrown at
/// one number at a time.
List<DartKey> ringKeys(int number) => [
  ('S$number', Dart.single(number)),
  ('D$number', Dart.double(number)),
  ('T$number', Dart.treble(number)),
];

/// The input pane of a game thrown at one target at a time: the few
/// darts that count, and a miss for everything else.
class DartKeysInput extends StatelessWidget {
  const DartKeysInput({
    super.key,
    required this.keys,
    required this.dartsInVisit,
    required this.onDart,
    required this.onEndVisit,
    required this.onUndo,
  });

  final List<DartKey> keys;
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
        children: [
          for (final (label, dart) in keys)
            PadKey(label: label, onTap: () => onDart(dart)),
        ],
      ),
      Row(
        children: [PadKey(label: 'Raté', onTap: () => onDart(Dart.miss))],
      ),
    ],
  );
}
