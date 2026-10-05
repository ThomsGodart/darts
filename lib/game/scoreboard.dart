import 'package:flutter/material.dart';

import '../theme/darts_space.dart';
import '../session/session.dart';
import '../theme/darts_tokens.dart';
import '../ui/average_label.dart';

/// Scoreboard-first view: the active player and their remaining score in
/// very large type, readable from the oche, always at the top; everyone
/// else in a compact list under it, which scrolls when they do not all
/// fit.
class Scoreboard extends StatelessWidget {
  const Scoreboard({super.key, required this.game, this.match});

  final X01Game game;

  /// The match the game is a leg of: every player then shows the legs,
  /// and the sets, they have won.
  final MatchScore? match;

  /// The most of the height the waiting players may take from the active
  /// one.
  static const _waitingShare = 0.45;

  @override
  Widget build(BuildContext context) {
    final waiting = game.waitingInTurnOrder;
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          Expanded(
            child: _ActivePlayer(game: game, match: match),
          ),
          if (waiting.isNotEmpty)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: constraints.maxHeight * _waitingShare,
              ),
              child: ListView(
                key: const Key('waiting-players'),
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  for (final score in waiting)
                    _WaitingPlayer(score: score, match: match),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// "T20 20 5 = 85" for a visit entered dart by dart, "85" for a total,
/// "BUST" in place of the points of a visit that busted.
String visitLabel(Visit visit) {
  final total = visit.isBust ? 'BUST' : '${visit.points}';
  return visit.thrown.isEmpty
      ? total
      : '${visit.thrown.map((d) => d.notation).join(' ')} = $total';
}

/// "moy. 45.2 · 12 fl."; empty before the first dart.
String _throwSummary(PlayerScore score, {int dartsInVisit = 0}) => [
  if (score.threeDartAverage case final average?)
    'moy. ${averageLabel(average)}',
  if (score.dartsThrown + dartsInVisit > 0)
    '${score.dartsThrown + dartsInVisit} fl.',
].join(' · ');

/// "Manches 2", or with sets "Sets 1 · Manches 2": what [player] has won
/// in [match].
String matchWinsLabel(MatchScore match, Player player) => [
  if (match.config.setsToWin > 1) 'Sets ${match.setsOf(player)}',
  'Manches ${match.legsOf(player)}',
].join(' · ');

class _MatchWins extends StatelessWidget {
  const _MatchWins({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: DartsSpace.sm,
      vertical: DartsSpace.xxs,
    ),
    decoration: BoxDecoration(
      border: Border.all(color: color),
      borderRadius: BorderRadius.circular(DartsSpace.md),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
    ),
  );
}

class _ActivePlayer extends StatelessWidget {
  const _ActivePlayer({required this.game, required this.match});

  final X01Game game;
  final MatchScore? match;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<DartsTokens>()!;
    final score = game.activeScore;
    final match = this.match;
    final checkout = game.checkoutSuggestion;
    final lastVisit = score.lastVisit;
    // The visit being entered busts: say so before the turn passes.
    final busts = game.visitBusts;
    final summary = _throwSummary(
      score,
      dartsInVisit: game.isFinished ? 0 : game.dartsInVisit.length,
    );
    final small = TextStyle(
      fontSize: tokens.visitSummaryFontSize,
      color: tokens.onActivePlayer,
    );
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
            if (match != null)
              _MatchWins(
                key: const Key('active-match-wins'),
                label: matchWinsLabel(match, score.player),
                color: tokens.onActivePlayer,
              ),
            Text(
              '${game.activeRemaining}',
              key: const Key('active-remaining'),
              style: TextStyle(
                fontSize: tokens.remainingFontSize,
                color: tokens.onActivePlayer,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
            if (busts)
              Container(
                key: const Key('active-bust'),
                color: tokens.bust,
                padding: const EdgeInsets.symmetric(horizontal: DartsSpace.sm),
                child: Text(
                  'BUST',
                  style: small.copyWith(
                    color: tokens.onBust,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            // Their visit before this one: a round old with others
            // playing, so it says what it is, and an old bust is not
            // flagged as if it were this visit's.
            if (lastVisit != null)
              Text(
                'Dernière volée : ${visitLabel(lastVisit)}',
                key: const Key('active-last-visit'),
                style: small,
              ),
            if (summary.isNotEmpty)
              Text(summary, key: const Key('active-summary'), style: small),
            if (checkout != null)
              Container(
                key: const Key('checkout-suggestion'),
                margin: const EdgeInsets.only(top: DartsSpace.sm),
                padding: const EdgeInsets.symmetric(
                  horizontal: DartsSpace.md,
                  vertical: DartsSpace.xs,
                ),
                decoration: BoxDecoration(
                  color: tokens.checkout,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  checkout.map((d) => d.notation).join('  '),
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
  const _WaitingPlayer({required this.score, required this.match});

  final PlayerScore score;
  final MatchScore? match;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<DartsTokens>()!;
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final match = this.match;
    final lastVisit = score.lastVisit;
    final busted = lastVisit?.isBust ?? false;
    final foreground = busted ? tokens.onBust : null;
    final summary = [
      if (lastVisit != null) visitLabel(lastVisit),
      _throwSummary(score),
    ].where((part) => part.isNotEmpty).join(' · ');
    return ListTile(
      tileColor: busted ? tokens.bust : null,
      textColor: foreground,
      title: Row(
        children: [
          Flexible(
            child: Text(
              score.player.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleLarge,
            ),
          ),
          if (match != null) ...[
            const SizedBox(width: DartsSpace.sm),
            _MatchWins(
              label: matchWinsLabel(match, score.player),
              color: foreground ?? colors.onSurfaceVariant,
            ),
          ],
        ],
      ),
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
