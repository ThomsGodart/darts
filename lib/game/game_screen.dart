import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../soiree/soiree.dart';
import '../soiree_controller.dart';
import '../ui/average_label.dart';
import 'scoreboard.dart';
import 'screen_awake.dart';
import 'turn_banner.dart';
import 'visit_input.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.controller,
    this.onChangeSetup,
    this.screenAwake = const WakelockScreenAwake(),
  });

  final SoireeController controller;

  /// Between games: lets players join, leave or reorder, or the rules
  /// change, then starts the next game. Null hides the option.
  final Future<void> Function()? onChangeSetup;
  final ScreenAwake screenAwake;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  SoireeController get controller => widget.controller;

  /// What the listener last saw, to tell a new game, a visit or an undo.
  late int _gamesSeen;
  late int _visitsSeen;
  bool _screenKeptOn = false;

  /// Name shown by the turn banner; null when no banner shows.
  String? _bannerPlayerName;

  /// Pointer-downs on the screen, to measure taps per visit (debug only).
  int _taps = 0;
  int _visitsCounted = 0;

  @override
  void initState() {
    super.initState();
    _gamesSeen = controller.state.games.length;
    _visitsSeen = controller.state.game!.visitsPlayed;
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
    final state = controller.state;
    final game = state.game!;
    final isNewGame = state.games.length != _gamesSeen;
    if (isNewGame) {
      // A new game: nothing to announce yet.
      setState(() => _bannerPlayerName = null);
    } else if (game.visitsPlayed > _visitsSeen && !game.isFinished) {
      // Only a completed visit passes the phone on; an undo does not.
      HapticFeedback.mediumImpact();
      setState(() => _bannerPlayerName = game.activePlayer.name);
    } else if (game.visitsPlayed < _visitsSeen) {
      setState(() => _bannerPlayerName = null);
    }
    if (!isNewGame) _visitsCounted += game.visitsPlayed - _visitsSeen;
    _gamesSeen = state.games.length;
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
            final bannerPlayerName = _bannerPlayerName;
            return Stack(
              children: [
                Column(
                  children: [
                    Expanded(child: Scoreboard(game: game)),
                    if (game.isFinished)
                      _GameOverPanel(
                        soiree: controller.state,
                        onRematch: controller.rematch,
                        onUndo: controller.undo,
                        onChangeSetup: widget.onChangeSetup,
                        onEnd: () => _endSoiree(context),
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
                if (bannerPlayerName != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: TurnBanner(
                      key: ValueKey(game.visitsPlayed),
                      playerName: bannerPlayerName,
                      onDone: () => setState(() => _bannerPlayerName = null),
                    ),
                  ),
                if (kDebugMode)
                  Positioned(
                    top: 4,
                    right: 8,
                    child: _TapCounter(taps: _taps, visits: _visitsCounted),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _endSoiree(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminer la soirée ?'),
        content: const Text('Elle passera dans l’historique.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuer'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    controller.endSoiree();
    Navigator.of(context).pop();
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

/// End of a game: the winner, everyone's averages, and what comes next.
class _GameOverPanel extends StatelessWidget {
  const _GameOverPanel({
    required this.soiree,
    required this.onRematch,
    required this.onUndo,
    required this.onEnd,
    this.onChangeSetup,
  });

  final SoireeState soiree;
  final VoidCallback onRematch;

  /// Reopens the game by taking back the checkout.
  final VoidCallback onUndo;
  final Future<void> Function()? onChangeSetup;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final game = soiree.game!;
    final showSoiree = soiree.games.length > 1;
    final onChangeSetup = this.onChangeSetup;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${game.winner!.name} gagne !',
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Table(
              key: const Key('game-averages'),
              columnWidths: const {0: FlexColumnWidth()},
              defaultColumnWidth: const IntrinsicColumnWidth(),
              children: [
                TableRow(
                  children: [
                    const SizedBox.shrink(),
                    _Cell('moy.', style: textTheme.labelMedium),
                    if (showSoiree)
                      _Cell('soirée', style: textTheme.labelMedium),
                  ],
                ),
                for (final score in game.scores)
                  TableRow(
                    children: [
                      Text(score.player.name, style: textTheme.titleMedium),
                      _Cell(averageLabel(score.threeDartAverage)),
                      if (showSoiree)
                        _Cell(averageLabel(soiree.averageOf(score.player))),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: onRematch,
                icon: const Icon(Icons.replay),
                label: Text('Rejouer', style: textTheme.titleLarge),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                if (onChangeSetup != null)
                  TextButton.icon(
                    onPressed: onChangeSetup,
                    icon: const Icon(Icons.group),
                    label: const Text('Changer…'),
                  ),
                TextButton.icon(
                  onPressed: onUndo,
                  icon: const Icon(Icons.undo),
                  label: const Text('Annuler le checkout'),
                ),
                TextButton.icon(
                  onPressed: onEnd,
                  icon: const Icon(Icons.nightlight),
                  label: const Text('Terminer la soirée'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.text, {this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 16),
    child: Text(text, textAlign: TextAlign.end, style: style),
  );
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
