import 'package:darts_points_counter/game/cricket_board.dart';
import 'package:darts_points_counter/session/session.dart';
import 'package:darts_points_counter/theme/app_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A cricket game with [count] players, a few darts in.
CricketGame gameWith(int count) {
  final session = Session(InMemoryJournal())
    ..startGame([
      for (var i = 1; i <= count; i++)
        Player(id: '$i', name: 'Joueur au nom long $i'),
    ], config: const CricketConfig());
  session
    ..throwDart(const Dart.treble(20))
    ..throwDart(const Dart.double(19))
    ..throwDart(Dart.bull);
  return session.state.game! as CricketGame;
}

Future<void> pumpBoard(
  WidgetTester tester,
  CricketGame game, {
  ValueChanged<Dart>? onDart,
}) async {
  // A 6.1" phone in portrait: 393 × 852 logical pixels.
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: themeById(defaultThemeId),
      home: Scaffold(
        body: CricketBoard(game: game, onDart: onDart),
      ),
    ),
  );
}

void main() {
  testWidgets('eight players fit a phone without overflow', (tester) async {
    await pumpBoard(tester, gameWith(maxPlayers));
    // A RenderFlex overflow would have failed the test already.
    expect(find.byKey(const Key('mark-closed')), findsOneWidget); // T20
    expect(find.text('X'), findsNWidgets(3)); // T20, D19 and the bull
    expect(tester.takeException(), isNull);
  });

  testWidgets('a lone player fits too', (tester) async {
    await pumpBoard(tester, gameWith(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('with the keys in the middle, one to eight players still fit', (
    tester,
  ) async {
    for (final count in [1, 2, maxPlayers]) {
      final thrown = <Dart>[];
      await pumpBoard(tester, gameWith(count), onDart: thrown.add);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('board-key-D19')));
      await tester.tap(find.byKey(const ValueKey('board-key-Bull')));
      expect(thrown, [const Dart.double(19), Dart.bull]);
    }
  });

  test('mark symbols: none, /, X, Ⓧ', () {
    expect([for (var m = 0; m <= 3; m++) markSymbol(m)], ['', '/', 'X', 'Ⓧ']);
  });
}
