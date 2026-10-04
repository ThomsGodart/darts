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

  test('the rules follow what was set up', () {
    String all(GameConfig config) => gameRules(config).join(' ');

    expect(all(const X01Config(startScore: 701)), contains('701'));
    expect(
      all(const X01Config(outRule: OutRule.master)),
      contains('un double ou un triple'),
    );
    expect(all(const X01Config()), isNot(contains('Double-in')));
    expect(all(const X01Config(doubleIn: true)), contains('Double-in'));
    expect(all(const X01Config(legsToWin: 3)), contains('premier à 3 manches'));
    expect(
      all(const CricketConfig(variant: CricketVariant.cutThroat)),
      contains('aux adversaires'),
    );
    expect(all(const GolfConfig(holes: 18)), contains('18 trous'));
    expect(
      all(const AroundTheClockConfig(finishOnBull: true)),
      contains('puis le bull'),
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
      ('Cricket', 'Règles · Cricket', 'Trois marques ferment'),
      ('Killer', 'Règles · Killer 3v', 'dernier en vie'),
      ('Halve-It', 'Règles · Halve-It', 'divise le score par 2'),
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

    expect(find.textContaining('divise le score'), findsNothing);
  });
}
