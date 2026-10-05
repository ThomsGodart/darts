import 'package:darts_points_counter/game/game_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('portrait stacks state over input', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 851));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameShell(
            statePane: SizedBox(key: Key('state'), height: 200),
            inputPane: SizedBox(key: Key('input'), height: 100),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('game-shell-landscape')), findsNothing);
    final state = tester.getCenter(find.byKey(const Key('game-shell-state')));
    final input = tester.getCenter(find.byKey(const Key('game-shell-input')));
    expect(state.dy, lessThan(input.dy));
  });

  testWidgets('landscape splits state left of input', (tester) async {
    await tester.binding.setSurfaceSize(const Size(851, 393));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameShell(
            statePane: SizedBox(key: Key('state'), height: 200),
            inputPane: SizedBox(key: Key('input'), height: 100),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('game-shell-landscape')), findsOneWidget);
    final state = tester.getCenter(find.byKey(const Key('game-shell-state')));
    final input = tester.getCenter(find.byKey(const Key('game-shell-input')));
    expect(state.dx, lessThan(input.dx));
  });

  testWidgets('in landscape the input takes all the height it is given', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 500));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final height in [350.0, 700.0]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameShell(
              statePane: const SizedBox.expand(),
              // A short pad, then one too tall for the screen.
              inputPane: SizedBox(height: height, child: const Placeholder()),
            ),
          ),
        ),
      );
      final input = tester.getRect(find.byKey(const Key('game-shell-input')));
      expect(input.height, closeTo(500, 1), reason: '$height');
      expect(input.width, lessThanOrEqualTo(450.5));
    }
  });
}
