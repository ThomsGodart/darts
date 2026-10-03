import 'package:flutter/material.dart';

import '../session/session.dart';
import '../theme/darts_space.dart';
import '../ui/game_labels.dart';
import '../ui/game_stats.dart';
import '../ui/stats_table_view.dart';
import 'formatting.dart';

/// One ended session: everyone's average over it, then each game with its
/// winner.
/// Pops true once the session was deleted.
class SessionDetailScreen extends StatelessWidget {
  const SessionDetailScreen({
    super.key,
    required this.record,
    required this.onDelete,
  });

  final SessionRecord record;
  final Future<void> Function() onDelete;

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette session ?'),
        content: const Text('Ses parties seront effacées pour de bon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await onDelete();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de supprimer cette session.')),
      );
      return;
    }
    if (context.mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final state = record.state;
    final overall = sessionStats(state);
    return Scaffold(
      appBar: AppBar(
        title: Text(sessionDate(record.createdAt)),
        actions: [
          IconButton(
            tooltip: 'Supprimer la session',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(DartsSpace.lg),
        children: [
          // Only X01 and cricket have a stat that spans games.
          if (overall.headings.isNotEmpty) ...[
            Text('Stats de la session', style: textTheme.titleLarge),
            const SizedBox(height: DartsSpace.sm),
            StatsTableView(key: const Key('session-stats'), stats: overall),
            const SizedBox(height: DartsSpace.xl),
          ],
          for (final (i, game) in state.games.indexed) ...[
            if (i > 0) const SizedBox(height: DartsSpace.xl),
            Text(
              'Partie ${i + 1} · ${configLabel(game.config)}',
              style: textTheme.titleMedium,
            ),
            Text(switch (game.winner) {
              final winner? => 'Gagnant : ${winner.name}',
              null => 'Non terminée',
            }, style: textTheme.bodyMedium),
            const SizedBox(height: DartsSpace.xs),
            StatsTableView(stats: gameStats(game)),
          ],
        ],
      ),
    );
  }
}
