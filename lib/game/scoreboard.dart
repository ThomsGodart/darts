import 'package:flutter/material.dart';

import '../theme/darts_space.dart';
import '../session/session.dart';
import '../theme/darts_tokens.dart';
import '../ui/average_label.dart';

/// Scoreboard-first view: the active player and their remaining score in
/// very large type, readable from the oche; everyone else in a compact list.
class Scoreboard extends StatelessWidget {
  const Scoreboard({super.key, required this.game});

  final X01Game game;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _ActivePlayer(
            score: game.activeScore,
            remaining: game.activeRemaining,
            checkout: game.checkoutSuggestion,
            // Alone, the last visit is the one just entered; with others it
            // is a round old and would read as the visit just typed.
            showLastVisit: game.scores.length == 1,
          ),
        ),
        for (final score in game.waitingInTurnOrder)
          _WaitingPlayer(score: score),
      ],
    );
  }
}

/// "60 · moy. 45.2", or "BUST · moy. 45.2"; empty before the first visit.
/// Without [withLastVisit], only the average.
String _visitSummary(PlayerScore score, {bool withLastVisit = true}) {
  final lastVisit = withLastVisit ? score.lastVisit : null;
  final average = score.threeDartAverage;
  return [
    if (lastVisit != null) lastVisit.isBust ? 'BUST' : '${lastVisit.points}',
    if (average != null) 'moy. ${averageLabel(average)}',
  ].join(' · ');
}

class _ActivePlayer extends StatelessWidget {
  const _ActivePlayer({
    required this.score,
    required this.remaining,
    required this.showLastVisit,
    this.checkout,
  });

  final PlayerScore score;
  final bool showLastVisit;

  /// Route to call for a checkout this visit; null when out of reach.
  final List<Dart>? checkout;

  /// Live remaining, darts of the visit in progress included.
  final int remaining;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<DartsTokens>()!;
    final busted = showLastVisit && (score.lastVisit?.isBust ?? false);
    final summary = _visitSummary(score, withLastVisit: showLastVisit);
    return Container(
      width: double.infinity,
      color: tokens.activePlayer,
      padding: const EdgeInsets.all(DartsSpace.lg),
      child: FittedBox(
        child: Column(
          children: [
            Text(
              score.player.name,
              key: const Key('active-name'),
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
                summary,
                style: TextStyle(
                  fontSize: tokens.visitSummaryFontSize,
                  color: busted ? tokens.onBust : tokens.onActivePlayer,
                ),
              ),
            ),
            if (checkout case final route?)
              Container(
                key: const Key('checkout-suggestion'),
                margin: const EdgeInsets.only(top: DartsSpace.sm),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: tokens.checkout,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  route.map((d) => d.notation).join('  '),
                  style: TextStyle(
                    fontSize: tokens.visitSummaryFontSize,
                    color: tokens.onCheckout,
                    fontWeight: FontWeight.bold,
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
