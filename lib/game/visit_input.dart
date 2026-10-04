import 'package:flutter/material.dart';

import '../session/session.dart';
import '../theme/darts_space.dart';
import 'dart_picker.dart';
import 'dartboard.dart';
import 'input_pane.dart';

/// Visit totals players hit most often, entered in a single tap.
const quickScores = [26, 41, 45, 60, 81, 85, 100, 140, 180];

/// How a visit is being entered.
enum VisitEntry {
  /// Dart by dart, on the keypad of numbers.
  keypad,

  /// Dart by dart, by touching a drawn board where each dart landed.
  target,

  /// As its total, in one go.
  total,
}

/// Bottom drawer to enter a visit: dart by dart on a keypad or a drawn
/// board, or as quick-scores or a typed total. Give it a new key on each
/// visit; [entry] says which way it opens. Without [onSubmit] (cricket),
/// only darts can be entered.
class VisitInput extends StatefulWidget {
  const VisitInput({
    super.key,
    this.onSubmit,
    required this.onDart,
    required this.onUndo,
    this.onEndVisit,
    this.dartsInVisit = const [],
    this.entry = VisitEntry.keypad,
    this.onEntryChanged,
  });

  /// Takes a visit total; null when the game only takes darts.
  final ValueChanged<int>? onSubmit;
  final ValueChanged<Dart> onDart;

  /// Darts already entered in this visit: until it ends, it cannot be
  /// entered as a total any more.
  final List<Dart> dartsInVisit;

  /// Takes back the latest input; null when there is nothing to undo.
  final VoidCallback? onUndo;

  /// Ends a visit entered dart by dart before its third dart; null hides
  /// the option.
  final VoidCallback? onEndVisit;

  /// The way the visit opens. [VisitEntry.total] only applies to a game
  /// that takes totals, and to a visit without a dart yet.
  final VisitEntry entry;

  /// Told when the players change the way they enter, so the next visit
  /// can open the way they left this one.
  final ValueChanged<VisitEntry>? onEntryChanged;

  @override
  State<VisitInput> createState() => _VisitInputState();
}

class _VisitInputState extends State<VisitInput> {
  String _typed = '';
  late VisitEntry _chosen = widget.entry;

  bool get _takesTotals => widget.onSubmit != null;

  /// A total needs a game that takes them, and a visit with no dart in.
  bool get _totalsAllowed => _takesTotals && widget.dartsInVisit.isEmpty;

  /// The way the visit is entered right now: what was chosen, unless a
  /// total cannot be entered.
  VisitEntry get _entry => _chosen == VisitEntry.total && !_totalsAllowed
      ? VisitEntry.keypad
      : _chosen;

  bool get _inDartMode => _entry != VisitEntry.total;

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
      header: _EntrySwitch(
        entry: _entry,
        // Once a dart is in, the visit is finished dart by dart.
        offered: [
          VisitEntry.keypad,
          VisitEntry.target,
          if (_takesTotals) VisitEntry.total,
        ],
        totalsAllowed: _totalsAllowed,
        onChanged: (entry) {
          setState(() => _chosen = entry);
          widget.onEntryChanged?.call(entry);
        },
      ),
      dartsInVisit: _inDartMode ? widget.dartsInVisit : null,
      onUndo: widget.onUndo,
      onEndVisit: _inDartMode ? widget.onEndVisit : null,
      secondaryAction: _inDartMode
          ? null
          : OutlinedButton(
              onPressed: () => _submit(0),
              child: const Text('0 / raté'),
            ),
      children: switch (_entry) {
        // Without totals (cricket), a miss changes nothing: no key.
        VisitEntry.keypad => [
          DartPicker(onDart: widget.onDart, showMiss: _takesTotals),
        ],
        VisitEntry.target => [
          Dartboard(onDart: widget.onDart),
          if (_takesTotals)
            Row(
              children: [
                PadKey(label: 'Raté', onTap: () => widget.onDart(Dart.miss)),
              ],
            ),
        ],
        VisitEntry.total => _totalPad(Theme.of(context).textTheme),
      },
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
              child: Text(
                '$score',
                style: textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
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

class _EntrySwitch extends StatelessWidget {
  const _EntrySwitch({
    required this.entry,
    required this.offered,
    required this.totalsAllowed,
    required this.onChanged,
  });

  final VisitEntry entry;
  final List<VisitEntry> offered;

  /// Whether the visit can still be entered as a total.
  final bool totalsAllowed;
  final ValueChanged<VisitEntry> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<VisitEntry>(
      segments: [
        for (final entry in offered)
          ButtonSegment(
            value: entry,
            enabled: entry != VisitEntry.total || totalsAllowed,
            label: Text(switch (entry) {
              VisitEntry.keypad => 'Fléchettes',
              VisitEntry.target => 'Cible',
              VisitEntry.total => 'Total',
            }),
          ),
      ],
      selected: {entry},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onChanged(selection.single),
    );
  }
}
