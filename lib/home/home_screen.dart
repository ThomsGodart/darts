import 'package:flutter/material.dart';

import '../game/game_screen.dart';
import '../setup/setup_controller.dart';
import '../setup/setup_screen.dart';
import '../soiree_controller.dart';
import '../soiree_launcher.dart';

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

  /// Shows the setup screen; null if the user backed out.
  Future<GameSetup?> _askSetup({GameSetup? from, String? title}) async {
    final setupController = widget.launcher.newSetup(from: from);
    final setup = await Navigator.of(context).push<GameSetup>(
      MaterialPageRoute(
        builder: (_) => SetupScreen(
          controller: setupController,
          title: title ?? 'Nouvelle soirée',
        ),
      ),
    );
    setupController.dispose();
    return setup;
  }

  Future<void> _newGame() async {
    final setup = await _askSetup();
    if (setup == null || !mounted) return;
    final controller = await widget.launcher.newGame(setup);
    if (!mounted) return controller.dispose();
    await _open(controller);
  }

  Future<void> _resume() async {
    final controller = await widget.launcher.resume();
    if (controller == null) return;
    if (!mounted) return controller.dispose();
    await _open(controller);
  }

  /// Between games: the setup screen, starting from the last game.
  Future<void> _changeSetup(SoireeController controller) async {
    final game = controller.state.game!;
    final setup = await _askSetup(
      from: (players: game.rematchOrder, config: game.config),
      title: 'Partie suivante',
    );
    if (setup == null || !mounted) return;
    await widget.launcher.nextGame(controller, setup);
  }

  Future<void> _open(SoireeController controller) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          controller: controller,
          onChangeSetup: () => _changeSetup(controller),
        ),
      ),
    );
    controller.dispose();
    if (!mounted) return;
    final canResume = widget.launcher.canResume();
    setState(() {
      _canResume = canResume;
    });
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
                      label: const Text('Reprendre la soirée'),
                    ),
                  );
                },
              ),
              FilledButton.tonal(
                onPressed: _newGame,
                child: const Text('Nouvelle soirée'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
