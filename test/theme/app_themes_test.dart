import 'package:darts_points_counter/theme/app_themes.dart';
import 'package:darts_points_counter/theme/darts_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the catalog exposes a theme with id "default"', () {
    expect(appThemes.keys, contains(defaultThemeId));
    expect(defaultThemeId, 'default');
  });

  test('every theme carries the app-specific darts tokens', () {
    for (final id in appThemes.keys) {
      final tokens = themeById(id).extension<DartsTokens>();
      expect(tokens, isNotNull, reason: 'theme "$id" has no DartsTokens');
      expect(tokens!.remainingFontSize, greaterThan(tokens.playerNameFontSize));
    }
  });

  test('an unknown id falls back to the default theme', () {
    expect(
      themeById('does-not-exist').extension<DartsTokens>(),
      themeById(defaultThemeId).extension<DartsTokens>(),
    );
  });

  test('tokens interpolate so theme transitions animate', () {
    final a = themeById(defaultThemeId).extension<DartsTokens>()!;
    final b = a.copyWith(remainingFontSize: a.remainingFontSize * 2);
    expect(a.lerp(b, 0.5).remainingFontSize, a.remainingFontSize * 1.5);
  });
}
