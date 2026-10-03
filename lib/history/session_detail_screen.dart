import 'package:flutter/material.dart';

import '../session/session.dart';
import '../ui/average_label.dart';
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
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Suppression impossible : $error')),
      );
      return;
    }
    if (context.mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final state = record.state;
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
        padding: const EdgeInsets.all(16),
        children: [
          Text('Moyennes de la session', style: textTheme.titleLarge),
          const SizedBox(height: 8),
          _AveragesTable(
            key: const Key('session-averages'),
            rows: [
              for (final player in state.players)
                (player.name, state.averageOf(player)),
            ],
          ),
          for (final (i, game) in state.games.indexed) ...[
            const SizedBox(height: 24),
            Text(
              'Partie ${i + 1} · ${configLabel(game.config)}',
              style: textTheme.titleMedium,
            ),
            Text(switch (game.winner) {
              final winner? => 'Gagnant : ${winner.name}',
              null => 'Non terminée',
            }, style: textTheme.bodyMedium),
            const SizedBox(height: 4),
            _AveragesTable(
              rows: [
                for (final score in game.scores)
                  (score.player.name, score.threeDartAverage),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AveragesTable extends StatelessWidget {
  const _AveragesTable({super.key, required this.rows});

  final List<(String, double?)> rows;

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {1: IntrinsicColumnWidth()},
      children: [
        for (final (name, value) in rows)
          TableRow(
            children: [
              Text(name),
              Text('moy. ${averageLabel(value)}', textAlign: TextAlign.end),
            ],
          ),
      ],
    );
  }
}
