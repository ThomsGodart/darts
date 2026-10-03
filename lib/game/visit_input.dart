import 'package:flutter/material.dart';

import '../session/session.dart';
import '../theme/darts_space.dart';
import 'dart_picker.dart';
import 'input_pane.dart';

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
    return InputPane(
      header: _takesTotals
          ? _ModeSwitch(
              dartByDart: _inDartMode,
              // Once a dart is in, the visit is finished dart by dart.
              onChanged: widget.dartsInVisit.isNotEmpty
                  ? null
                  : (value) => setState(() => _dartByDart = value),
            )
          : null,
      dartsInVisit: _inDartMode ? widget.dartsInVisit : null,
      onUndo: widget.onUndo,
      onEndVisit: _inDartMode ? widget.onEndVisit : null,
      secondaryAction: _inDartMode
          ? null
          : OutlinedButton(
              onPressed: () => _submit(0),
              child: const Text('0 / raté'),
            ),
      children: _inDartMode
          ? [DartPicker(onDart: widget.onDart)]
          : _totalPad(Theme.of(context).textTheme),
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
            PadKey(
              label: '$digit',
              large: true,
              onTap: () => _appendDigit(digit),
            ),
        ],
      ),
    Row(
      children: [
        PadKey(label: 'C', large: true, onTap: _clear),
        PadKey(label: '0', large: true, onTap: () => _appendDigit(0)),
        PadKey(
          label: 'OK',
          large: true,
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
