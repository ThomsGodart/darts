import 'package:flutter/material.dart';

import 'darts_tokens.dart';

/// Id of the theme used when none is chosen or an id is unknown.
const defaultThemeId = 'default';

/// Theme catalog, keyed by a stable string id.
final Map<String, ThemeData> appThemes = {defaultThemeId: _buildDefault()};

/// Resolves a theme id, falling back to [defaultThemeId].
ThemeData themeById(String id) => appThemes[id] ?? appThemes[defaultThemeId]!;

ThemeData _buildDefault() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF1B5E20),
    brightness: Brightness.dark,
  );
  return ThemeData(
    colorScheme: colorScheme,
    extensions: const [
      DartsTokens(
        activePlayer: Color(0xFFFFC107),
        onActivePlayer: Color(0xFF000000),
        // Darker red so onBust (white) clears WCAG AA 4.5:1.
        bust: Color(0xFFB71C1C),
        onBust: Color(0xFFFFFFFF),
        // Near-black green so onCheckout (white) clears WCAG AA 4.5:1.
        checkout: Color(0xFF0B3D0F),
        onCheckout: Color(0xFFFFFFFF),
        cricketMark: Color(0xFFE0E0E0),
        // Light enough to clear 4.5:1 on the amber-tinted active column too.
        cricketClosed: Color(0xFF81C784),
        cricketDead: Color(0xFF616161),
        cricketActiveColumn: Color(0x40FFC107),
        remainingFontSize: 120,
        playerNameFontSize: 40,
        compactRemainingFontSize: 32,
        visitSummaryFontSize: 20,
        cricketMarkFontSize: 34,
        cricketPointsFontSize: 36,
      ),
    ],
  );
}
