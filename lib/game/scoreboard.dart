import 'package:flutter/material.dart';

import '../soiree/soiree.dart';
import '../theme/darts_tokens.dart';

/// Scoreboard-first view: the active player and their remaining score in
/// very large type, readable from the oche; everyone else in a compact list.
class Scoreboard extends StatelessWidget {
  const Scoreboard({super.key, required this.game});

  final GameState game;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _ActivePlayer(score: game.activeScore)),
        for (final score in game.waitingInTurnOrder)
          _WaitingPlayer(score: score),
      ],
    );
  }
}

class _ActivePlayer extends StatelessWidget {
  const _ActivePlayer({required this.score});

  final PlayerScore score;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<DartsTokens>()!;
    return Container(
      width: double.infinity,
      color: tokens.activePlayer,
      padding: const EdgeInsets.all(16),
      child: FittedBox(
        child: Column(
          children: [
            Text(
              score.player.name,
              style: TextStyle(
                fontSize: tokens.playerNameFontSize,
                color: tokens.onActivePlayer,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${score.remaining}',
              key: const Key('active-remaining'),
              style: TextStyle(
                fontSize: tokens.remainingFontSize,
                color: tokens.onActivePlayer,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaitingPlayer extends StatelessWidget {
  const _WaitingPlayer({required this.score});

  final PlayerScore score;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<DartsTokens>()!;
    final textTheme = Theme.of(context).textTheme;
    final lastVisit = score.lastVisit;
    return ListTile(
      title: Text(score.player.name, style: textTheme.titleLarge),
      subtitle: lastVisit == null ? null : Text('Dernière volée : $lastVisit'),
      trailing: Text(
        '${score.remaining}',
        style: TextStyle(
          fontSize: tokens.compactRemainingFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
