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
                  _GameOverPanel(winner: game.winner!)
                else
                  VisitInput(onSubmit: (score) => _submit(context, score)),
              ],
            );
          },
        ),
      ),
    );
  }

  void _submit(BuildContext context, int score) {
    if (controller.submitVisitTotal(score) is Rejected) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Score invalide : $score')));
    }
  }
}

class _GameOverPanel extends StatelessWidget {
  const _GameOverPanel({required this.winner});

  final Player winner;

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
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Accueil'),
          ),
        ],
      ),
    );
  }
}
