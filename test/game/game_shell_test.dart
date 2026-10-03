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
}
