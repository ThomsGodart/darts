import 'package:flutter/material.dart';

/// Visit totals players hit most often, entered in a single tap.
const quickScores = [26, 41, 45, 60, 81, 85, 100, 140, 180];

/// Bottom drawer to enter a visit: quick-scores, or a typed total.
class VisitInput extends StatefulWidget {
  const VisitInput({super.key, required this.onSubmit});

  final ValueChanged<int> onSubmit;

  @override
  State<VisitInput> createState() => _VisitInputState();
}

class _VisitInputState extends State<VisitInput> {
  String _typed = '';

  void _appendDigit(int digit) {
    if (_typed.length >= 3) return;
    setState(() => _typed = _typed == '0' ? '$digit' : '$_typed$digit');
  }

  void _clear() => setState(() => _typed = '');

  void _submit(int score) {
    setState(() => _typed = '');
    widget.onSubmit(score);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: colors.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                for (final score in quickScores)
                  ActionChip(
                    label: Text('$score', style: textTheme.titleMedium),
                    onPressed: () => _submit(score),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _typed.isEmpty ? '–' : _typed,
              key: const Key('typed-total'),
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
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
                  onTap: _typed.isEmpty
                      ? null
                      : () => _submit(int.parse(_typed)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _submit(0),
                child: const Text('0 / raté'),
              ),
            ),
          ],
        ),
      ),
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
        padding: const EdgeInsets.all(3),
        child: SizedBox(
          height: 48,
          child: emphasized
              ? FilledButton(onPressed: onTap, child: child)
              : FilledButton.tonal(onPressed: onTap, child: child),
        ),
      ),
    );
  }
}
