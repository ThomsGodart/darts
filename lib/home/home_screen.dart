import 'package:flutter/material.dart';

import '../game/game_screen.dart';
import '../history/history_screen.dart';
import '../settings/app_settings.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';
import '../session/session.dart';
import '../setup/setup_screen.dart';
import '../session_controller.dart';
import '../session_launcher.dart';
import '../theme/darts_space.dart';
import '../ui/persist_failure_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.launcher, required this.settings});

  final SessionLauncher launcher;
  final AppSettings settings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Whether a session was left open: mid-game, or between two games.
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
      // [SessionLauncher] already notified watchers; the banner shows.
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
    // Same players, same game as last time: one tap to play again.
    final last = await widget.launcher.lastSetup();
    if (!mounted) return;
    final setup = await _askSetup(from: last);
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
        title: const Text('Une session est en cours'),
        content: const Text(
          'La terminer pour en commencer une nouvelle ? '
          'Elle passera dans l’historique au lancement de la nouvelle partie.',
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

  Future<void> _openStats() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          StatsScreen(launcher: widget.launcher, settings: widget.settings),
    ),
  );

  Future<void> _openSettings() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SettingsScreen(settings: widget.settings),
    ),
  );

  /// The setup screen for the next game of [controller]'s session,
  /// starting from [from], or from the last game with its order turned.
  /// Says whether a game was started.
  Future<bool> _changeSetup(
    SessionController controller, {
    GameSetup? from,
    String title = 'Partie suivante',
  }) async {
    if (_changingSetup) return false;
    _changingSetup = true;
    try {
      final setup = await _askSetup(
        from: from ?? controller.nextSetup,
        title: title,
      );
      if (setup == null || !mounted) return false;
      await widget.launcher.nextGame(controller, setup);
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de lancer la partie. Réessayez.'),
          ),
        );
      }
      return false;
    } finally {
      _changingSetup = false;
    }
  }

  Future<void> _open(SessionController controller) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          controller: controller,
          launcher: widget.launcher,
          portraitLock: widget.settings.portraitLock,
          onChangeSetup: () => _changeSetup(controller),
          onCancelGame: (cancelled) => _changeSetup(
            controller,
            from: cancelled,
            title: 'Nouvelle partie',
          ),
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
    final launcher = widget.launcher;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            key: const Key('settings-button'),
            tooltip: 'Réglages',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: launcher,
          builder: (context, _) => Column(
            children: [
              if (launcher.persistFailure != null) const PersistFailureBanner(),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(DartsSpace.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Darts', style: textTheme.displayMedium),
                        const SizedBox(height: DartsSpace.xxl),
                        FutureBuilder(
                          future: _canResume,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState !=
                                ConnectionState.done) {
                              return const Padding(
                                padding: EdgeInsets.only(bottom: DartsSpace.md),
                                child: SizedBox(
                                  key: Key('home-resume-loading'),
                                  width: DartsSpace.tap,
                                  height: DartsSpace.tap,
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            if (snapshot.hasError) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: DartsSpace.md,
                                ),
                                child: Text(
                                  'Impossible de vérifier une session en cours.',
                                  key: const Key('home-resume-error'),
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              );
                            }
                            if (snapshot.data == true) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: DartsSpace.md,
                                ),
                                child: FilledButton.icon(
                                  onPressed: _resume,
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('Reprendre la session'),
                                ),
                              );
                            }
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: DartsSpace.md,
                              ),
                              child: Text(
                                'Aucune session à reprendre',
                                key: const Key('home-resume-empty'),
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            );
                          },
                        ),
                        FilledButton.tonal(
                          onPressed: _newGame,
                          child: const Text('Nouvelle session'),
                        ),
                        const SizedBox(height: DartsSpace.md),
                        TextButton.icon(
                          onPressed: _openHistory,
                          icon: const Icon(Icons.history),
                          label: const Text('Historique'),
                        ),
                        TextButton.icon(
                          onPressed: _openStats,
                          icon: const Icon(Icons.bar_chart),
                          label: const Text('Statistiques'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
