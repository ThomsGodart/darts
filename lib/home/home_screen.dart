import 'package:flutter/material.dart';

import '../game/game_screen.dart';
import '../soiree/soiree.dart';
import '../soiree_controller.dart';

/// Placeholder players until the soirée setup exists (ticket 08).
const _fixedPlayers = [
  Player(id: 'player-1', name: 'Joueur 1'),
  Player(id: 'player-2', name: 'Joueur 2'),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.newSoiree});

  final SoireeController Function() newSoiree;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SoireeController? _controller;

  void _startGame() {
    _controller?.dispose();
    final controller = widget.newSoiree()..startGame(_fixedPlayers);
    _controller = controller;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(controller: controller),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
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
              FilledButton(
                onPressed: _startGame,
                child: const Text('Nouvelle partie 501'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
