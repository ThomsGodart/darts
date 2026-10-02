import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../soiree/soiree.dart';
import '../soiree_controller.dart';
import 'scoreboard.dart';
import 'screen_awake.dart';
import 'turn_banner.dart';
import 'visit_input.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.controller,
    this.screenAwake = const WakelockScreenAwake(),
  });

  final SoireeController controller;
  final ScreenAwake screenAwake;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  SoireeController get controller => widget.controller;

  late int _visitsSeen;
  bool _screenKeptOn = false;

  /// Next player to announce after a visit; null when no banner shows.
  String? _announced;

  /// Pointer-downs on the screen, to measure taps per visit (debug only).
  int _taps = 0;
  int _visitsAtOpen = 0;

  @override
  void initState() {
    super.initState();
    _visitsSeen = _visitsAtOpen = controller.state.game!.visitsPlayed;
    controller.addListener(_onGameChanged);
    if (kDebugMode) {
      GestureBinding.instance.pointerRouter.addGlobalRoute(_countTap);
    }
    _syncScreenAwake();
  }

  @override
  void dispose() {
    controller.removeListener(_onGameChanged);
    if (kDebugMode) {
      GestureBinding.instance.pointerRouter.removeGlobalRoute(_countTap);
    }
    if (_screenKeptOn) widget.screenAwake.release();
    super.dispose();
  }

  void _countTap(PointerEvent event) {
    if (event is PointerDownEvent) _taps++;
  }

  void _onGameChanged() {
    final game = controller.state.game!;
    // Only a completed visit passes the phone on; an undo does not.
    if (game.visitsPlayed > _visitsSeen && !game.isFinished) {
      HapticFeedback.mediumImpact();
      setState(() => _announced = game.activePlayer.name);
    }
    _visitsSeen = game.visitsPlayed;
    _syncScreenAwake();
  }

  void _syncScreenAwake() {
    final inProgress = !controller.state.game!.isFinished;
    if (inProgress == _screenKeptOn) return;
    _screenKeptOn = inProgress;
    inProgress ? widget.screenAwake.keepOn() : widget.screenAwake.release();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final game = controller.state.game!;
            final announced = _announced;
            return Stack(
              children: [
                Column(
                  children: [
                    Expanded(child: Scoreboard(game: game)),
                    if (game.isFinished)
                      _GameOverPanel(
                        winner: game.winner!,
                        onUndo: controller.undo,
                      )
                    else
                      VisitInput(
                        key: ValueKey(game.visitsPlayed),
                        onSubmit: (score) => _submit(context, game, score),
                        onDart: controller.throwDart,
                        dartsInVisit: game.dartsInVisit,
                        onUndo: controller.canUndo ? controller.undo : null,
                      ),
                  ],
                ),
                if (announced != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: TurnBanner(
                      key: ValueKey(game.visitsPlayed),
                      playerName: announced,
                      onDone: () => setState(() => _announced = null),
                    ),
                  ),
                if (kDebugMode)
                  Positioned(
                    top: 4,
                    right: 8,
                    child: _TapCounter(
                      taps: _taps,
                      visits: game.visitsPlayed - _visitsAtOpen,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context, GameState game, int score) async {
    int? dartsAtCheckout;
    final options = game.checkoutDartOptions(score);
    if (options.length == 1) {
      dartsAtCheckout = options.single;
    } else if (options.isNotEmpty) {
      dartsAtCheckout = await _askCheckoutDarts(context, options);
      if (dartsAtCheckout == null || !context.mounted) return;
    }
    final result = controller.submitVisitTotal(
      score,
      dartsAtCheckout: dartsAtCheckout,
    );
    if (result is Rejected && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Score invalide : $score')));
    }
  }
}

/// Asks how many darts the checkout took; null if dismissed.
Future<int?> _askCheckoutDarts(BuildContext context, List<int> options) {
  return showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Combien de fléchettes ?'),
      actions: [
        for (final darts in options)
          FilledButton(
            onPressed: () => Navigator.of(context).pop(darts),
            child: Text('$darts'),
          ),
      ],
    ),
  );
}

class _GameOverPanel extends StatelessWidget {
  const _GameOverPanel({required this.winner, required this.onUndo});

  final Player winner;

  /// Reopens the game by taking back the checkout.
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${winner.name} gagne !', style: textTheme.headlineMedium),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onUndo,
                icon: const Icon(Icons.undo),
                label: const Text('Annuler le checkout'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Accueil'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Debug-only measure of the "≤ 2 taps per visit" goal.
class _TapCounter extends StatelessWidget {
  const _TapCounter({required this.taps, required this.visits});

  final int taps;
  final int visits;

  @override
  Widget build(BuildContext context) {
    if (visits <= 0) return const SizedBox.shrink();
    return Text(
      '${(taps / visits).toStringAsFixed(1)} taps/volée',
      style: Theme.of(context).textTheme.labelSmall,
    );
  }
}
