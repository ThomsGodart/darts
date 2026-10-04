import 'package:darts_points_counter/session/session.dart';
import 'package:darts_points_counter/ui/game_rules.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_test_harness.dart';

void main() {
  test('every game has its rules spelled out', () {
    for (final kind in GameKind.values) {
      final rules = gameRules(defaultConfigOf(kind));
      expect(rules.length, greaterThanOrEqualTo(3), reason: kind.name);
      for (final rule in rules) {
        expect(rule, endsWith('.'), reason: '${kind.name}: $rule');
      }
    }
  });

  test('the rules state the numbers the game is scored with', () {
    String all(GameConfig config) => gameRules(config).join(' ');

    // Golf: what the last dart costs.
    for (final (dart, strokes) in [
      (const Dart.double(3), 1),
      (const Dart.treble(3), 3),
      (const Dart.single(3), 4),
      (Dart.miss, 5),
    ]) {
      expect(golfStrokes(dart, hole: 3), strokes);
    }
    expect(all(const GolfConfig()), contains('double du numéro, 1 coup'));
    expect(all(const GolfConfig()), contains('triple, 3 coups'));
    expect(all(const GolfConfig()), contains('simple, 4 coups'));
    expect(all(const GolfConfig()), contains('$golfMissStrokes coups'));

    expect(all(const HalveItConfig()), contains('part de $halveItStartScore.'));
    expect(
      all(const HalveItConfig()),
      contains('20, 16, double 7, 14, triple 10, 17, puis le centre'),
    );
    expect(
      [for (final target in halveItTargets) target.label],
      ['20', '16', 'D7', '14', 'T10', '17', 'Bull'],
    );
    expect(all(const Bobs27Config()), contains('part de $bobs27StartScore'));
    expect(all(const CountUpConfig()), contains('8 manches'));
    expect(all(const BaseballConfig()), contains('$baseballInnings manches'));
  });

  test('the rules follow what was set up', () {
    String all(GameConfig config) => gameRules(config).join(' ');

    expect(all(const X01Config(startScore: 701)), contains('701'));
    expect(
      all(const X01Config(outRule: OutRule.master)),
      contains('un double ou un triple'),
    );
    expect(
      all(const X01Config(outRule: OutRule.straight)),
      contains('n’importe quelle fléchette'),
    );
    expect(all(const X01Config()), isNot(contains('Double-in')));
    expect(all(const X01Config(doubleIn: true)), contains('Double-in'));
    expect(all(const X01Config(legsToWin: 3)), contains('premier à 3 manches'));
    expect(
      all(const CricketConfig(variant: CricketVariant.cutThroat)),
      contains('Les points sont une pénalité'),
    );
    expect(all(const GolfConfig(holes: 18)), contains('18 trous'));
    expect(all(const AroundTheClockConfig()), contains('puis le centre'));
    expect(
      all(const AroundTheClockConfig(finishOnBull: false)),
      isNot(contains('puis le centre')),
    );
    expect(all(const KillerConfig(lives: 5)), contains('5 vies'));
    expect(all(const KillerConfig(doublesToKiller: 3)), contains('3 fois'));
    expect(
      all(const ShanghaiConfig(length: ShanghaiLength.fourteenToTwenty)),
      contains('du 14 au 20'),
    );
    expect(
      all(const ShanghaiConfig(instantShanghai: false)),
      isNot(contains('immédiatement')),
    );
  });

  testWidgets('the Règles button is always there, for the game picked', (
    tester,
  ) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await tester.tap(find.text('Nouvelle session'));
    await tester.pumpAndSettle();

    for (final (game, title, words) in [
      ('X01', 'Règles · 501 Double-out', 'exactement à 0'),
      ('Cricket', 'Règles · Cricket', 'fermé quand un joueur y a 3 marques'),
      ('Killer', 'Règles · Killer 3v', 'Le dernier en vie gagne'),
      ('Halve-It', 'Règles · Halve-It', 'est divisé par 2'),
    ]) {
      await tapInSetup(tester, game);
      await tester.tap(find.byKey(const Key('rules-button')));
      await tester.pumpAndSettle();

      final dialog = find.byKey(const Key('rules-dialog'));
      expect(
        find.descendant(of: dialog, matching: find.text(title)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.textContaining(words)),
        findsOneWidget,
        reason: game,
      );
      await tester.tap(find.text('Compris'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('no rules are spelled out on the setup screen itself', (
    tester,
  ) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await tester.tap(find.text('Nouvelle session'));
    await tester.pumpAndSettle();
    await tapInSetup(tester, 'Halve-It');

    expect(find.textContaining('divisé par 2'), findsNothing);
  });
}
