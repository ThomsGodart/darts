import 'package:flutter/material.dart';

import '../game/game_screen.dart';
import '../soiree/soiree.dart';
import '../soiree_controller.dart';
import '../soiree_launcher.dart';

/// Placeholder players until the soirée setup exists (ticket 08).
const _fixedPlayers = [
  Player(id: 'player-1', name: 'Joueur 1'),
  Player(id: 'player-2', name: 'Joueur 2'),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.launcher});

  final SoireeLauncher launcher;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// The soirée left in progress, offered for resuming; null if none.
  late Future<SoireeController?> _resumable;

  @override
  void initState() {
    super.initState();
    _resumable = widget.launcher.resumable();
  }

  Future<void> _newGame() async {
    _open(await widget.launcher.newGame(_fixedPlayers));
  }

  Future<void> _open(SoireeController controller) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(controller: controller),
      ),
    );
    controller.dispose();
    if (!mounted) return;
    setState(() => _resumable = widget.launcher.resumable());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Darts', style: textTheme.displayMedium),
              const SizedBox(height: 32),
              FutureBuilder(
                future: _resumable,
                builder: (context, snapshot) {
                  final resumable = snapshot.data;
                  if (resumable == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FilledButton.icon(
                      onPressed: () => _open(resumable),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Reprendre la partie'),
                    ),
                  );
                },
              ),
              FilledButton.tonal(
                onPressed: _newGame,
                child: const Text('Nouvelle partie 501'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
