import 'package:darts_points_counter/theme/app_themes.dart';
import 'package:darts_points_counter/theme/contrast.dart';
import 'package:darts_points_counter/theme/darts_space.dart';
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

  test('semantic text-on-color pairs meet WCAG AA 4.5:1', () {
    final tokens = themeById(defaultThemeId).extension<DartsTokens>()!;
    expect(
      contrastRatio(tokens.onCheckout, tokens.checkout),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrastRatio(tokens.onBust, tokens.bust),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrastRatio(tokens.onActivePlayer, tokens.activePlayer),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('spacing scale exposes a 48 dp tap target', () {
    expect(DartsSpace.tap, 48);
    expect(DartsSpace.sm, lessThan(DartsSpace.md));
    expect(DartsSpace.md, lessThan(DartsSpace.lg));
  });
}
