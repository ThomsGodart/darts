import 'package:flutter/material.dart';

import '../soiree/soiree.dart';
import '../soiree_controller.dart';
import 'scoreboard.dart';
import 'visit_input.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key, required this.controller});

  final SoireeController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final game = controller.state.game!;
            return Column(
              children: [
                Expanded(child: Scoreboard(game: game)),
                if (game.isFinished)
                  _GameOverPanel(winner: game.winner!, onUndo: controller.undo)
                else
                  VisitInput(
                    onSubmit: (score) => _submit(context, game, score),
                    onUndo: controller.canUndo ? controller.undo : null,
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
