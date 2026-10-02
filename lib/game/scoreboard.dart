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
        Expanded(
          child: _ActivePlayer(
            score: game.activeScore,
            remaining: game.activeRemaining,
          ),
        ),
        for (final score in game.waitingInTurnOrder)
          _WaitingPlayer(score: score),
      ],
    );
  }
}

/// "60 · moy. 45.2", or "BUST · moy. 45.2"; empty before the first visit.
String _visitSummary(PlayerScore score) {
  final lastVisit = score.lastVisit;
  final average = score.threeDartAverage;
  return [
    if (lastVisit != null) lastVisit.isBust ? 'BUST' : '${lastVisit.points}',
    if (average != null) 'moy. ${average.toStringAsFixed(1)}',
  ].join(' · ');
}

class _ActivePlayer extends StatelessWidget {
  const _ActivePlayer({required this.score, required this.remaining});

  final PlayerScore score;

  /// Live remaining, darts of the visit in progress included.
  final int remaining;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<DartsTokens>()!;
    final busted = score.lastVisit?.isBust ?? false;
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
              '$remaining',
              key: const Key('active-remaining'),
              style: TextStyle(
                fontSize: tokens.remainingFontSize,
                color: tokens.onActivePlayer,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
            // With a single player, their own bust is shown here.
            Container(
              color: busted ? tokens.bust : null,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _visitSummary(score),
                style: TextStyle(
                  fontSize: tokens.visitSummaryFontSize,
                  color: busted ? tokens.onBust : tokens.onActivePlayer,
                ),
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
    final busted = score.lastVisit?.isBust ?? false;
    final foreground = busted ? tokens.onBust : null;
    final summary = _visitSummary(score);
    return ListTile(
      tileColor: busted ? tokens.bust : null,
      textColor: foreground,
      title: Text(score.player.name, style: textTheme.titleLarge),
      subtitle: summary.isEmpty ? null : Text(summary),
      trailing: Text(
        '${score.remaining}',
        style: TextStyle(
          fontSize: tokens.compactRemainingFontSize,
          fontWeight: FontWeight.bold,
          color: foreground,
        ),
      ),
    );
  }
}
