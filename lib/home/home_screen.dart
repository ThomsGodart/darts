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
  /// Whether a soirée was left with a game in progress.
  late Future<bool> _canResume;

  /// Stores what was played before the OS may kill the backgrounded app.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _canResume = widget.launcher.canResume();
    _lifecycle = AppLifecycleListener(onPause: _flush, onDetach: _flush);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _flush() async {
    try {
      await widget.launcher.flush();
    } catch (_) {
      // Already logged by the repository; the game goes on from memory.
    }
  }

  Future<void> _newGame() async {
    final controller = await widget.launcher.newGame(_fixedPlayers);
    if (!mounted) return controller.dispose();
    await _open(controller);
  }

  Future<void> _resume() async {
    final controller = await widget.launcher.resume();
    if (controller == null) return;
    if (!mounted) return controller.dispose();
    await _open(controller);
  }

  Future<void> _open(SoireeController controller) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(controller: controller),
      ),
    );
    controller.dispose();
    if (!mounted) return;
    setState(() => _canResume = widget.launcher.canResume());
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
                future: _canResume,
                builder: (context, snapshot) {
                  if (snapshot.data != true) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FilledButton.icon(
                      onPressed: _resume,
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
