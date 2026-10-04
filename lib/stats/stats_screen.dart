import 'package:flutter/material.dart';

import '../session/session.dart';
import '../session_launcher.dart';
import '../theme/darts_space.dart';
import '../ui/average_label.dart';

/// Each player's stats over every session played on this phone.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key, required this.launcher});

  final SessionLauncher launcher;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late final Future<List<PlayerStats>> _stats = widget.launcher.playerStats();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques')),
      body: FutureBuilder(
        future: _stats,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Impossible de charger les statistiques.',
                key: Key('stats-load-error'),
                textAlign: TextAlign.center,
              ),
            );
          }
          final stats = snapshot.data;
          if (stats == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (stats.isEmpty) {
            return const Center(
              child: Text('Aucune partie jouée pour l’instant'),
            );
          }
          // Whoever played most comes first.
          final byGames = [...stats]
            ..sort((a, b) => b.gamesPlayed.compareTo(a.gamesPlayed));
          return ListView.separated(
            padding: const EdgeInsets.all(DartsSpace.lg),
            itemCount: byGames.length,
            separatorBuilder: (_, _) => const Divider(height: DartsSpace.xxl),
            itemBuilder: (context, i) => _PlayerStatsView(stats: byGames[i]),
          );
        },
      ),
    );
  }
}

/// "Parties gagnées" and its value, and so on: what [stats] has to say.
List<(String, String)> playerStatsLines(PlayerStats stats) => [
  ('Parties terminées', '${stats.gamesPlayed}'),
  (
    'Parties gagnées',
    stats.gamesPlayed == 0
        ? '${stats.gamesWon}'
        : '${stats.gamesWon} '
              '(${(100 * stats.gamesWon / stats.gamesPlayed).round()} %)',
  ),
  if (stats.x01Average != null) ...[
    ('Moyenne X01', averageLabel(stats.x01Average)),
    ('Moyenne des 9 premières', averageLabel(stats.firstNineAverage)),
    ('100+ · 140+ · 180', '${stats.tons} · ${stats.ton40s} · ${stats.ton80s}'),
    if (stats.bestCheckout case final checkout?)
      ('Meilleure finition', '$checkout'),
    if (stats.fewestDartsToWin case final darts?)
      ('Manche la plus courte', '$darts fléchettes'),
  ],
  if (stats.marksPerRound != null)
    ('MPR Cricket', averageLabel(stats.marksPerRound)),
];

class _PlayerStatsView extends StatelessWidget {
  const _PlayerStatsView({required this.stats});

  final PlayerStats stats;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(stats.player.name, style: textTheme.titleLarge),
        const SizedBox(height: DartsSpace.sm),
        Table(
          columnWidths: const {1: IntrinsicColumnWidth()},
          children: [
            for (final (label, value) in playerStatsLines(stats))
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: DartsSpace.xxs,
                    ),
                    child: Text(label, style: textTheme.bodyLarge),
                  ),
                  Text(
                    value,
                    textAlign: TextAlign.end,
                    style: textTheme.titleMedium,
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
