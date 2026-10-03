import 'package:flutter/material.dart';

import '../game/game_screen.dart';
import '../history/history_screen.dart';
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
  /// Whether a soirée was left open: mid-game, or between two games.
  late Future<bool> _canResume;

  /// Set while the setup of a next game is open: blocks a second one.
  bool _changingSetup = false;

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
        builder: (_) => title == null
            ? SetupScreen(controller: setupController)
            : SetupScreen(controller: setupController, title: title),
      ),
    );
    setupController.dispose();
    return setup;
  }

  Future<void> _newGame() async {
    if (await widget.launcher.canResume()) {
      if (!mounted || !await _confirmAbandon()) return;
    }
    if (!mounted) return;
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

  Future<bool> _confirmAbandon() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Une soirée est en cours'),
        content: const Text(
          'La terminer pour en commencer une nouvelle ? '
          'Elle passera dans l’historique.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Terminer et commencer'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _openHistory() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => HistoryScreen(launcher: widget.launcher),
    ),
  );

  /// Between games: the setup screen, starting from the last game.
  Future<void> _changeSetup(SoireeController controller) async {
    if (_changingSetup) return;
    _changingSetup = true;
    try {
      final setup = await _askSetup(
        from: controller.nextSetup,
        title: 'Partie suivante',
      );
      if (setup == null || !mounted) return;
      await widget.launcher.nextGame(controller, setup);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de lancer la partie : $error')),
      );
    } finally {
      _changingSetup = false;
    }
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
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _openHistory,
                icon: const Icon(Icons.history),
                label: const Text('Historique'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
