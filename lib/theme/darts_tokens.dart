import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// App-specific design tokens, on top of Material's [ColorScheme].
///
/// Screens read colors and scoreboard sizes from here, never hardcode them,
/// so new themes (pro players, custom darts) are just new token sets.
@immutable
class DartsTokens extends ThemeExtension<DartsTokens> {
  const DartsTokens({
    required this.activePlayer,
    required this.onActivePlayer,
    required this.bust,
    required this.onBust,
    required this.checkout,
    required this.onCheckout,
    required this.cricketMark,
    required this.cricketClosed,
    required this.cricketDeadRow,
    required this.cricketDead,
    required this.cricketActiveColumn,
    required this.remainingFontSize,
    required this.playerNameFontSize,
    required this.compactRemainingFontSize,
    required this.visitSummaryFontSize,
    required this.cricketMarkFontSize,
    required this.cricketPointsFontSize,
  });

  /// Highlight of the player whose turn it is.
  final Color activePlayer;

  final Color onActivePlayer;

  /// Signal shown when a visit busts.
  final Color bust;

  final Color onBust;

  /// Accent when the remaining score is finishable.
  final Color checkout;

  final Color onCheckout;

  /// Marks on a number still open for that player.
  final Color cricketMark;

  /// The ringed mark on a number the player has closed.
  final Color cricketClosed;

  /// Background of the row of a number every player has closed.
  final Color cricketDeadRow;

  /// The label of a number every player has closed: it no longer scores.
  final Color cricketDead;

  /// Background of the active player's column on the cricket board.
  final Color cricketActiveColumn;

  /// Active player's remaining score, meant to be read from 2–3 m.
  final double remainingFontSize;

  /// Active player's name on the scoreboard.
  final double playerNameFontSize;

  /// Remaining score of waiting players in the compact list.
  final double compactRemainingFontSize;

  /// Last visit and average under the active player's remaining score.
  final double visitSummaryFontSize;

  /// Marks on the cricket board, meant to be read from 2–3 m.
  final double cricketMarkFontSize;

  /// Points under the cricket board.
  final double cricketPointsFontSize;

  @override
  DartsTokens copyWith({
    Color? activePlayer,
    Color? onActivePlayer,
    Color? bust,
    Color? onBust,
    Color? checkout,
    Color? onCheckout,
    Color? cricketMark,
    Color? cricketClosed,
    Color? cricketDeadRow,
    Color? cricketDead,
    Color? cricketActiveColumn,
    double? remainingFontSize,
    double? playerNameFontSize,
    double? compactRemainingFontSize,
    double? visitSummaryFontSize,
    double? cricketMarkFontSize,
    double? cricketPointsFontSize,
  }) {
    return DartsTokens(
      activePlayer: activePlayer ?? this.activePlayer,
      onActivePlayer: onActivePlayer ?? this.onActivePlayer,
      bust: bust ?? this.bust,
      onBust: onBust ?? this.onBust,
      checkout: checkout ?? this.checkout,
      onCheckout: onCheckout ?? this.onCheckout,
      cricketMark: cricketMark ?? this.cricketMark,
      cricketClosed: cricketClosed ?? this.cricketClosed,
      cricketDeadRow: cricketDeadRow ?? this.cricketDeadRow,
      cricketDead: cricketDead ?? this.cricketDead,
      cricketActiveColumn: cricketActiveColumn ?? this.cricketActiveColumn,
      remainingFontSize: remainingFontSize ?? this.remainingFontSize,
      playerNameFontSize: playerNameFontSize ?? this.playerNameFontSize,
      compactRemainingFontSize:
          compactRemainingFontSize ?? this.compactRemainingFontSize,
      visitSummaryFontSize: visitSummaryFontSize ?? this.visitSummaryFontSize,
      cricketMarkFontSize: cricketMarkFontSize ?? this.cricketMarkFontSize,
      cricketPointsFontSize:
          cricketPointsFontSize ?? this.cricketPointsFontSize,
    );
  }

  @override
  DartsTokens lerp(DartsTokens? other, double t) {
    if (other == null) return this;
    return DartsTokens(
      activePlayer: Color.lerp(activePlayer, other.activePlayer, t)!,
      onActivePlayer: Color.lerp(onActivePlayer, other.onActivePlayer, t)!,
      bust: Color.lerp(bust, other.bust, t)!,
      onBust: Color.lerp(onBust, other.onBust, t)!,
      checkout: Color.lerp(checkout, other.checkout, t)!,
      onCheckout: Color.lerp(onCheckout, other.onCheckout, t)!,
      cricketMark: Color.lerp(cricketMark, other.cricketMark, t)!,
      cricketClosed: Color.lerp(cricketClosed, other.cricketClosed, t)!,
      cricketDeadRow: Color.lerp(cricketDeadRow, other.cricketDeadRow, t)!,
      cricketDead: Color.lerp(cricketDead, other.cricketDead, t)!,
      cricketActiveColumn: Color.lerp(
        cricketActiveColumn,
        other.cricketActiveColumn,
        t,
      )!,
      remainingFontSize: lerpDouble(
        remainingFontSize,
        other.remainingFontSize,
        t,
      )!,
      playerNameFontSize: lerpDouble(
        playerNameFontSize,
        other.playerNameFontSize,
        t,
      )!,
      compactRemainingFontSize: lerpDouble(
        compactRemainingFontSize,
        other.compactRemainingFontSize,
        t,
      )!,
      visitSummaryFontSize: lerpDouble(
        visitSummaryFontSize,
        other.visitSummaryFontSize,
        t,
      )!,
      cricketMarkFontSize: lerpDouble(
        cricketMarkFontSize,
        other.cricketMarkFontSize,
        t,
      )!,
      cricketPointsFontSize: lerpDouble(
        cricketPointsFontSize,
        other.cricketPointsFontSize,
        t,
      )!,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DartsTokens &&
      other.activePlayer == activePlayer &&
      other.onActivePlayer == onActivePlayer &&
      other.bust == bust &&
      other.onBust == onBust &&
      other.checkout == checkout &&
      other.onCheckout == onCheckout &&
      other.cricketMark == cricketMark &&
      other.cricketClosed == cricketClosed &&
      other.cricketDeadRow == cricketDeadRow &&
      other.cricketDead == cricketDead &&
      other.cricketActiveColumn == cricketActiveColumn &&
      other.remainingFontSize == remainingFontSize &&
      other.playerNameFontSize == playerNameFontSize &&
      other.compactRemainingFontSize == compactRemainingFontSize &&
      other.visitSummaryFontSize == visitSummaryFontSize &&
      other.cricketMarkFontSize == cricketMarkFontSize &&
      other.cricketPointsFontSize == cricketPointsFontSize;

  @override
  int get hashCode => Object.hashAll([
    activePlayer,
    onActivePlayer,
    bust,
    onBust,
    checkout,
    onCheckout,
    cricketMark,
    cricketClosed,
    cricketDeadRow,
    cricketDead,
    cricketActiveColumn,
    remainingFontSize,
    playerNameFontSize,
    compactRemainingFontSize,
    visitSummaryFontSize,
    cricketMarkFontSize,
    cricketPointsFontSize,
  ]);
}
