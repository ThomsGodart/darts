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
    _reload();
  }

  void _reload() {
    final history = widget.launcher.history();
    setState(() {
      _history = history;
    });
  }

  /// A long press on a session: deletes it, once the players confirm.
  Future<void> _delete(SessionRecord record) => _confirmThenDelete(
    title: 'Supprimer cette session ?',
    content:
        '${sessionDate(record.createdAt)} · '
        '${gamesCount(record.state.games.length)}. '
        'Ses parties seront effacées pour de bon.',
    confirm: 'Supprimer',
    delete: () => widget.launcher.deleteSession(record),
  );

  Future<void> _deleteAll(int sessions) => _confirmThenDelete(
    title: 'Tout effacer ?',
    content:
        '${sessions == 1 ? 'La session' : 'Les $sessions sessions'} de '
        'l’historique et leurs statistiques seront effacées pour de bon. '
        'Les joueurs et la session en cours restent.',
    confirm: 'Tout effacer',
    delete: widget.launcher.deleteHistory,
  );

  Future<void> _confirmThenDelete({
    required String title,
    required String content,
    required String confirm,
    required Future<void> Function() delete,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await delete();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Impossible de supprimer.')));
    }
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _history,
      builder: (context, snapshot) => Scaffold(
        appBar: AppBar(
          title: const Text('Historique'),
          actions: [
            if (snapshot.data case final history? when history.isNotEmpty)
              PopupMenuButton<void>(
                key: const Key('history-menu'),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: () => _deleteAll(history.length),
                    child: const Text('Tout effacer'),
                  ),
                ],
              ),
          ],
        ),
        body: Builder(
          builder: (context) {
            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'Impossible de charger l’historique.',
                  key: Key('history-load-error'),
                  textAlign: TextAlign.center,
                ),
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
                    // A session with a team game says so.
                    leading: record.state.games.any(hasTeam)
                        ? const Icon(
                            Icons.groups_outlined,
                            semanticLabel: 'Avec des parties en équipe',
                          )
                        : null,
                    title: Text(sessionDate(record.createdAt)),
                    subtitle: Text(
                      [
                        record.state.players.map((p) => p.name).join(', '),
                        gamesCount(record.state.games.length),
                      ].join(' · '),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(record),
                    onLongPress: () => _delete(record),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
