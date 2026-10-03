import 'package:flutter/material.dart';

import '../session/session.dart';
import '../session_launcher.dart';
import 'formatting.dart';
import 'session_detail_screen.dart';

/// Ended sessions, newest first.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.launcher});

  final SessionLauncher launcher;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<SessionRecord>> _history = widget.launcher.history();

  Future<void> _open(SessionRecord record) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SessionDetailScreen(
          record: record,
          onDelete: () => widget.launcher.deleteSession(record),
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
          if (snapshot.hasError) {
            return Center(
              child: Text('Historique illisible : ${snapshot.error}'),
            );
          }
          final history = snapshot.data;
          if (history == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (history.isEmpty) {
            return const Center(child: Text('Aucune session pour l’instant'));
          }
          return ListView(
            children: [
              for (final record in history)
                ListTile(
                  title: Text(sessionDate(record.createdAt)),
                  subtitle: Text(
                    [
                      record.state.players.map((p) => p.name).join(', '),
                      gamesCount(record.state.games.length),
                    ].join(' · '),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(record),
                ),
            ],
          );
        },
      ),
    );
  }
}
