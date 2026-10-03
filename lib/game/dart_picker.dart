import 'package:flutter/material.dart';

import '../session/session.dart';
import '../theme/darts_space.dart';

/// Enters one dart: pick single, double or treble, then the sector.
class DartPicker extends StatefulWidget {
  const DartPicker({super.key, required this.onDart});

  final ValueChanged<Dart> onDart;

  @override
  State<DartPicker> createState() => _DartPickerState();
}

class _DartPickerState extends State<DartPicker> {
  int _multiplier = 1;

  void _throw(Dart dart) {
    // Most darts are singles: back to single after each one.
    setState(() => _multiplier = 1);
    widget.onDart(dart);
  }

  Dart _sector(int sector) => switch (_multiplier) {
    2 => Dart.double(sector),
    3 => Dart.treble(sector),
    _ => Dart.single(sector),
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 1, label: Text('Simple')),
            ButtonSegment(value: 2, label: Text('Double')),
            ButtonSegment(value: 3, label: Text('Triple')),
          ],
          selected: {_multiplier},
          showSelectedIcon: false,
          onSelectionChanged: (s) => setState(() => _multiplier = s.single),
        ),
        const SizedBox(height: DartsSpace.xs),
        for (var row = 0; row < 4; row++)
          Row(
            children: [
              for (var sector = row * 5 + 1; sector <= row * 5 + 5; sector++)
                _DartKey(
                  label: _sector(sector).notation,
                  onTap: () => _throw(_sector(sector)),
                ),
            ],
          ),
        Row(
          children: [
            _DartKey(label: '25', onTap: () => _throw(Dart.outerBull)),
            _DartKey(label: 'Bull', onTap: () => _throw(Dart.bull)),
            _DartKey(label: 'Raté', onTap: () => _throw(Dart.miss)),
          ],
        ),
      ],
    );
  }
}

class _DartKey extends StatelessWidget {
  const _DartKey({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(DartsSpace.xxs),
        child: SizedBox(
          height: DartsSpace.tap,
          child: FilledButton.tonal(
            onPressed: onTap,
            style: FilledButton.styleFrom(padding: EdgeInsets.zero),
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
        ),
      ),
    );
  }
}
