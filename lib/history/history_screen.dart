import 'package:flutter/material.dart';

import '../soiree/soiree.dart';
import '../soiree_launcher.dart';
import 'formatting.dart';
import 'soiree_detail_screen.dart';

/// Past soirées, newest first; the open one is marked as such.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.launcher});

  final SoireeLauncher launcher;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<SoireeRecord>> _history = widget.launcher.history();

  Future<void> _open(SoireeRecord record) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SoireeDetailScreen(
          record: record,
          onDelete: () => widget.launcher.deleteSoiree(record),
        ),
      ),
    );
    if (deleted != true || !mounted) return;
    final history = widget.launcher.history();
    setState(() {
      _history = history;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: FutureBuilder(
        future: _history,
        builder: (context, snapshot) {
          final history = snapshot.data;
          if (history == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (history.isEmpty) {
            return const Center(child: Text('Aucune soirée pour l’instant'));
          }
          return ListView(
            children: [
              for (final record in history)
                ListTile(
                  title: Text(soireeDate(record.createdAt)),
                  subtitle: Text(
                    [
                      record.state.players.map((p) => p.name).join(', '),
                      gamesCount(record.state.games.length),
                    ].join(' · '),
                  ),
                  trailing: record.state.isEnded
                      ? const Icon(Icons.chevron_right)
                      : const Chip(label: Text('en cours')),
                  onTap: () => _open(record),
                ),
            ],
          );
        },
      ),
    );
  }
}
