import 'package:flutter/material.dart';

import '../theme/darts_space.dart';
import 'game_stats.dart';

/// A [StatsTable]: a heading row, then a row per player.
class StatsTableView extends StatelessWidget {
  const StatsTableView({super.key, required this.stats});

  final StatsTable stats;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Table(
      columnWidths: const {0: FlexColumnWidth()},
      defaultColumnWidth: const IntrinsicColumnWidth(),
      children: [
        TableRow(
          children: [
            const SizedBox.shrink(),
            for (final heading in stats.headings)
              _Cell(heading, style: textTheme.labelMedium),
          ],
        ),
        for (final (player, values) in stats.rows)
          TableRow(
            children: [
              Text(player.name, style: textTheme.titleMedium),
              for (final value in values) _Cell(value),
            ],
          ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.text, {this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: DartsSpace.lg),
    child: Text(text, textAlign: TextAlign.end, style: style),
  );
}
