import 'package:flutter/material.dart';

import '../session/session.dart';
import '../theme/darts_space.dart';
import 'dart_picker.dart';

/// Visit totals players hit most often, entered in a single tap.
const quickScores = [26, 41, 45, 60, 81, 85, 100, 140, 180];

/// Bottom drawer to enter a visit: quick-scores or a typed total, or dart
/// by dart for this visit only. Give it a new key on each visit so the
/// next one starts back in total mode. Without [onSubmit] (cricket), only
/// darts can be entered.
class VisitInput extends StatefulWidget {
  const VisitInput({
    super.key,
    this.onSubmit,
    required this.onDart,
    required this.onUndo,
    this.onEndVisit,
    this.dartsInVisit = const [],
  });

  /// Takes a visit total; null when the game only takes darts.
  final ValueChanged<int>? onSubmit;
  final ValueChanged<Dart> onDart;

  /// Darts already entered in this visit; the visit stays in dart mode
  /// until it ends.
  final List<Dart> dartsInVisit;

  /// Takes back the latest input; null when there is nothing to undo.
  final VoidCallback? onUndo;

  /// Ends a visit entered dart by dart before its third dart; null hides
  /// the option.
  final VoidCallback? onEndVisit;

  @override
  State<VisitInput> createState() => _VisitInputState();
}

class _VisitInputState extends State<VisitInput> {
  String _typed = '';
  bool _dartByDart = false;

  bool get _takesTotals => widget.onSubmit != null;

  bool get _inDartMode =>
      !_takesTotals || _dartByDart || widget.dartsInVisit.isNotEmpty;

  void _appendDigit(int digit) {
    if (_typed.length >= 3) return;
    setState(() => _typed = _typed == '0' ? '$digit' : '$_typed$digit');
  }

  void _clear() => setState(() => _typed = '');

  void _submit(int score) {
    setState(() => _typed = '');
    widget.onSubmit?.call(score);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: colors.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(DartsSpace.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_takesTotals) ...[
              _ModeSwitch(
                dartByDart: _inDartMode,
                // Once a dart is in, the visit is finished dart by dart.
                onChanged: widget.dartsInVisit.isNotEmpty
                    ? null
                    : (value) => setState(() => _dartByDart = value),
              ),
              const SizedBox(height: DartsSpace.sm),
            ],
            if (_inDartMode) ...[
              Text(
                [
                  for (var i = 0; i < dartsPerVisit; i++)
                    widget.dartsInVisit.elementAtOrNull(i)?.notation ?? '–',
                ].join('  ·  '),
                key: const Key('darts-in-visit'),
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: DartsSpace.sm),
              DartPicker(onDart: widget.onDart),
            ] else
              ..._totalPad(textTheme),
            const SizedBox(height: DartsSpace.xs),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onUndo,
                    icon: const Icon(Icons.undo),
                    label: const Text('Annuler la saisie'),
                  ),
                ),
                if (_inDartMode) ...[
                  if (widget.onEndVisit case final onEndVisit?) ...[
                    const SizedBox(width: DartsSpace.sm),
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: onEndVisit,
                        child: const Text('Fin de tour'),
                      ),
                    ),
                  ],
                ] else ...[
                  const SizedBox(width: DartsSpace.sm),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _submit(0),
                      child: const Text('0 / raté'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _totalPad(TextTheme textTheme) => [
    // Quick-scores are primary: filled, large targets.
    Wrap(
      spacing: DartsSpace.sm,
      runSpacing: DartsSpace.sm,
      alignment: WrapAlignment.center,
      children: [
        for (final score in quickScores)
          SizedBox(
            height: DartsSpace.tap,
            child: FilledButton(
              onPressed: () => _submit(score),
              child: Text('$score', style: textTheme.titleMedium),
            ),
          ),
      ],
    ),
    const SizedBox(height: DartsSpace.sm),
    Text(
      _typed.isEmpty ? '–' : _typed,
      key: const Key('typed-total'),
      style: textTheme.headlineMedium,
    ),
    const SizedBox(height: DartsSpace.sm),
    // Digits are secondary to the quick-scores.
    for (final row in const [
      [1, 2, 3],
      [4, 5, 6],
      [7, 8, 9],
    ])
      Row(
        children: [
          for (final digit in row)
            _PadKey(label: '$digit', onTap: () => _appendDigit(digit)),
        ],
      ),
    Row(
      children: [
        _PadKey(label: 'C', onTap: _clear),
        _PadKey(label: '0', onTap: () => _appendDigit(0)),
        _PadKey(
          label: 'OK',
          emphasized: true,
          onTap: _typed.isEmpty ? null : () => _submit(int.parse(_typed)),
        ),
      ],
    ),
  ];
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.dartByDart, required this.onChanged});

  final bool dartByDart;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(value: false, label: Text('Total')),
        ButtonSegment(value: true, label: Text('Fléchettes')),
      ],
      selected: {dartByDart},
      showSelectedIcon: false,
      onSelectionChanged: onChanged == null
          ? null
          : (selection) => onChanged(selection.single),
    );
  }
}

class _PadKey extends StatelessWidget {
  const _PadKey({
    required this.label,
    required this.onTap,
    this.emphasized = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleLarge;
    final child = Text(label, style: style);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(DartsSpace.xxs),
        child: SizedBox(
          height: DartsSpace.tap,
          child: emphasized
              ? FilledButton(onPressed: onTap, child: child)
              : FilledButton.tonal(onPressed: onTap, child: child),
        ),
      ),
    );
  }
}
