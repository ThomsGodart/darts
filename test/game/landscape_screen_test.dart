import 'package:darts_points_counter/session/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_test_harness.dart';
import 'game_screen_test.dart' show activeRemaining;

/// Wide landscape surface so [GameShell] splits.
const landscapeSize = Size(900, 500);

Future<void> toLandscape(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(landscapeSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('X01 landscape splits and keeps a dart visit', (tester) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await launchGame(tester);
    await tester.tap(find.text('Fléchettes'));
    await tester.pump();
    await tester.tap(find.text('Triple'));
    await tester.pump();
    await tester.tap(find.text('T20'));
    await tester.pump();

    await toLandscape(tester);

    expect(find.byKey(const Key('game-shell-landscape')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('darts-in-visit'))).data,
      contains('T20'),
    );
    expect(activeRemaining(tester), '441');
  });

  testWidgets('Cricket landscape shows board and dart pad', (tester) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await launchGame(tester, const ['Joueur 1', 'Joueur 2'], 'Cricket');
    await toLandscape(tester);

    expect(find.byKey(const Key('game-shell-landscape')), findsOneWidget);
    expect(find.byKey(const Key('cricket-board')), findsOneWidget);
    expect(find.byKey(const Key('darts-in-visit')), findsOneWidget);
    // Marks left, D/S/T keys in the input pane — not cramped on the board.
    final board = find.byKey(const Key('cricket-board'));
    final input = find.byKey(const Key('game-shell-input'));
    expect(
      find.descendant(
        of: board,
        matching: find.byKey(const ValueKey('board-key-T20')),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: input,
        matching: find.byKey(const ValueKey('board-key-T20')),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('board-key-T20')));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('darts-in-visit'))).data,
      contains('T20'),
    );
  });

  testWidgets('Cricket landscape turns off the keys of a dead number', (
    tester,
  ) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await launchGame(tester, const ['Joueur 1', 'Joueur 2'], 'Cricket');
    await toLandscape(tester);

    FilledButton key(String notation) => tester.widget<FilledButton>(
      find.byKey(ValueKey('board-key-$notation')),
    );

    // Both players close the 20: nobody scores on it any more.
    for (var player = 0; player < 2; player++) {
      await tester.tap(find.byKey(const ValueKey('board-key-T20')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('end-visit')));
      await tester.pumpAndSettle();
    }

    expect(key('T20').onPressed, isNull);
    expect(key('20').onPressed, isNull);
    expect(key('T19').onPressed, isNotNull);
  });

  testWidgets('Shanghai landscape shows board and S/D/T', (tester) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await launchGame(tester, const ['Joueur 1', 'Joueur 2'], 'Shanghai');
    await toLandscape(tester);

    expect(find.byKey(const Key('game-shell-landscape')), findsOneWidget);
    expect(find.byKey(const Key('shanghai-board')), findsOneWidget);
    expect(find.text('S1'), findsOneWidget);
  });

  testWidgets('Killer landscape shows board and attribution pad', (
    tester,
  ) async {
    final storage = AppStorage();
    final catalog = InMemoryPlayerCatalog(storage.players);
    await catalog.add('Joueur 1');
    await catalog.add('Joueur 2');
    await catalog.add('Joueur 3');
    await pumpApp(tester, storage);
    await launchGame(tester, const [
      'Joueur 1',
      'Joueur 2',
      'Joueur 3',
    ], 'Killer');
    await toLandscape(tester);

    expect(find.byKey(const Key('game-shell-landscape')), findsOneWidget);
    expect(find.byKey(const Key('killer-board')), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
  });
}
