import 'package:flutter/material.dart';

import '../session/session.dart';
import '../theme/darts_space.dart';
import 'input_pane.dart';

/// Enters one dart: pick single, double or treble, then the sector.
class DartPicker extends StatefulWidget {
  const DartPicker({super.key, required this.onDart, this.showMiss = true});

  final ValueChanged<Dart> onDart;

  /// Whether a miss has its key; false where ending the visit says it.
  final bool showMiss;

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

  /// The key of a bull, off while a double or a treble is being picked.
  VoidCallback? _onBull(Dart dart) =>
      _multiplier == 1 ? () => _throw(dart) : null;

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
        SectorGrid(
          labelOf: (sector) => _sector(sector).notation,
          onSector: (sector) => _throw(_sector(sector)),
        ),
        Row(
          children: [
            // The bull is the double of 25 already: neither has a ring
            // to pick.
            PadKey(label: '25', onTap: _onBull(Dart.outerBull)),
            PadKey(label: 'Bull 50', onTap: _onBull(Dart.bull)),
            if (widget.showMiss)
              PadKey(label: 'Raté', onTap: () => _throw(Dart.miss)),
          ],
        ),
        const SizedBox(height: DartsSpace.xs),
        // Under the numbers it applies to, away from the switch between
        // the ways of entering a visit.
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<int>(
            key: const Key('ring-picker'),
            segments: const [
              ButtonSegment(value: 1, label: Text('Simple')),
              ButtonSegment(value: 2, label: Text('Double')),
              ButtonSegment(value: 3, label: Text('Triple')),
            ],
            selected: {_multiplier},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _multiplier = s.single),
          ),
        ),
      ],
    );
  }
}
