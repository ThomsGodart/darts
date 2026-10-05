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

/// "T20 - 20 - 5 = 85" for a visit entered dart by dart, "85" for a total,
/// "BUST" in place of the points of a visit that busted.
String visitLabel(Visit visit) => [
  if (visit.thrown.isNotEmpty) visitDarts(visit),
  visitTotal(visit),
].join(' = ');

/// "T20 - 20 - 5"; empty for a visit entered as a total.
String visitDarts(Visit visit) =>
    visit.thrown.map((d) => d.notation).join(' - ');

/// "85", or "BUST".
String visitTotal(Visit visit) => visit.isBust ? 'BUST' : '${visit.points}';

/// "Manches 2 · moy. 45.2 · 12 fl.": what [score]'s player has won in
/// [match], if the game is a leg of one, then how they throw; empty
/// before the first dart of a game played alone.
String _summary(PlayerScore score, MatchScore? match, {int dartsInVisit = 0}) =>
    [
      if (match != null) matchWinsLabel(match, score.player),
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

/// A player's last visit, next to their remaining score: its darts when
/// they were entered, over what it scored.
class _LastVisit extends StatelessWidget {
  const _LastVisit({
    super.key,
    required this.visit,
    required this.color,
    required this.dartsStyle,
    required this.totalStyle,
    this.heading,
  });

  final Visit? visit;
  final Color? color;
  final TextStyle? dartsStyle;
  final TextStyle? totalStyle;

  /// Says what the figures are, where they could be taken for the visit
  /// being entered.
  final String? heading;

  @override
  Widget build(BuildContext context) {
    final visit = this.visit;
    final heading = this.heading;
    if (visit == null) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (heading != null)
          Text(heading, style: dartsStyle?.copyWith(color: color)),
        if (visit.thrown.isNotEmpty)
          Text(
            visitDarts(visit),
            maxLines: 1,
            style: dartsStyle?.copyWith(color: color),
          ),
        Text(
          visitTotal(visit),
          style: totalStyle?.copyWith(color: color, height: 1.1),
        ),
      ],
    );
  }
}

class _ActivePlayer extends StatelessWidget {
  const _ActivePlayer({required this.game, required this.match});

  final X01Game game;
  final MatchScore? match;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<DartsTokens>()!;
    final score = game.activeScore;
    final checkout = game.checkoutSuggestion;
    // A team's score has several throwers behind it, named in the banner
    // over the board: its block is the score to read from the oche, and
    // nothing that would be one member's.
    final isTeam = score.player.isTeam;
    // The visit being entered busts: say so before the turn passes.
    final busts = game.visitBusts;
    final summary = _summary(
      score,
      match,
      dartsInVisit: game.isFinished ? 0 : game.dartsInVisit.length,
    );
    final small = TextStyle(
      fontSize: tokens.visitSummaryFontSize,
      color: tokens.onActivePlayer,
    );
    final remaining = Text(
      '${game.activeRemaining}',
      key: const Key('active-remaining'),
      style: TextStyle(
        fontSize: tokens.remainingFontSize,
        color: tokens.onActivePlayer,
        fontWeight: FontWeight.bold,
        height: 1,
      ),
    );
    return Container(
      width: double.infinity,
      color: tokens.activePlayer,
      padding: const EdgeInsets.all(DartsSpace.lg),
      child: FittedBox(
        child: Column(
          children: [
            if (!isTeam)
              Text(
                score.player.name,
                key: const Key('active-name'),
                style: TextStyle(
                  fontSize: tokens.playerNameFontSize,
                  color: tokens.onActivePlayer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (isTeam || score.lastVisit == null)
              remaining
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  remaining,
                  const SizedBox(width: DartsSpace.lg),
                  // Their visit before this one: a round old with others
                  // playing, so it says what it is, and an old bust is
                  // not flagged as if it were this visit's.
                  _LastVisit(
                    key: const Key('active-last-visit'),
                    visit: score.lastVisit,
                    heading: 'Dernière volée',
                    color: tokens.onActivePlayer,
                    dartsStyle: small,
                    totalStyle: small.copyWith(
                      fontSize: tokens.visitSummaryFontSize * 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
            if (!isTeam && summary.isNotEmpty)
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

  /// Room kept for the last visit, so that the remaining scores line up.
  static const _visitWidth = 84.0;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<DartsTokens>()!;
    final textTheme = Theme.of(context).textTheme;
    final lastVisit = score.lastVisit;
    final busted = lastVisit?.isBust ?? false;
    final foreground = busted ? tokens.onBust : null;
    final summary = _summary(score, match);
    return ListTile(
      tileColor: busted ? tokens.bust : null,
      textColor: foreground,
      title: Text(
        score.player.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textTheme.titleLarge,
      ),
      subtitle: summary.isEmpty
          ? null
          : Text(
              summary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(color: foreground),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${score.remaining}',
            style: TextStyle(
              fontSize: tokens.compactRemainingFontSize,
              fontWeight: FontWeight.bold,
              color: foreground,
            ),
          ),
          const SizedBox(width: DartsSpace.sm),
          SizedBox(
            width: _visitWidth,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerEnd,
              child: _LastVisit(
                visit: lastVisit,
                color: foreground,
                dartsStyle: textTheme.bodyMedium,
                totalStyle: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
