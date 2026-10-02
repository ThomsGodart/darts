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
    required this.remainingFontSize,
    required this.playerNameFontSize,
    required this.compactRemainingFontSize,
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

  /// Active player's remaining score, meant to be read from 2–3 m.
  final double remainingFontSize;

  /// Active player's name on the scoreboard.
  final double playerNameFontSize;

  /// Remaining score of waiting players in the compact list.
  final double compactRemainingFontSize;

  @override
  DartsTokens copyWith({
    Color? activePlayer,
    Color? onActivePlayer,
    Color? bust,
    Color? onBust,
    Color? checkout,
    Color? onCheckout,
    double? remainingFontSize,
    double? playerNameFontSize,
    double? compactRemainingFontSize,
  }) {
    return DartsTokens(
      activePlayer: activePlayer ?? this.activePlayer,
      onActivePlayer: onActivePlayer ?? this.onActivePlayer,
      bust: bust ?? this.bust,
      onBust: onBust ?? this.onBust,
      checkout: checkout ?? this.checkout,
      onCheckout: onCheckout ?? this.onCheckout,
      remainingFontSize: remainingFontSize ?? this.remainingFontSize,
      playerNameFontSize: playerNameFontSize ?? this.playerNameFontSize,
      compactRemainingFontSize:
          compactRemainingFontSize ?? this.compactRemainingFontSize,
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
      other.remainingFontSize == remainingFontSize &&
      other.playerNameFontSize == playerNameFontSize &&
      other.compactRemainingFontSize == compactRemainingFontSize;

  @override
  int get hashCode => Object.hash(
    activePlayer,
    onActivePlayer,
    bust,
    onBust,
    checkout,
    onCheckout,
    remainingFontSize,
    playerNameFontSize,
    compactRemainingFontSize,
  );
}
