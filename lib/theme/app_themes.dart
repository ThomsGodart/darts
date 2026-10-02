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
        onActivePlayer: Color(0xFF1A1A1A),
        bust: Color(0xFFE53935),
        onBust: Color(0xFFFFFFFF),
        checkout: Color(0xFF43A047),
        onCheckout: Color(0xFFFFFFFF),
        remainingFontSize: 120,
        playerNameFontSize: 40,
        compactRemainingFontSize: 32,
      ),
    ],
  );
}
