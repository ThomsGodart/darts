import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_test_harness.dart';

void main() {
  testWidgets('Shanghai shows the number and S/D/T pad', (tester) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await launchGame(tester, const ['Joueur 1', 'Joueur 2'], 'Shanghai');

    expect(find.byKey(const Key('shanghai-board')), findsOneWidget);
    expect(find.byKey(const Key('shanghai-number')), findsOneWidget);
    expect(find.text('S1'), findsOneWidget);
    expect(find.text('D1'), findsOneWidget);
    expect(find.text('T1'), findsOneWidget);
    expect(find.text('Fin de tour'), findsOneWidget);
  });

  testWidgets('a Shanghai scores on the board', (tester) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await launchGame(tester, const ['Joueur 1', 'Joueur 2'], 'Shanghai');
    await tester.tap(find.text('T1'));
    await tester.pump();
    await tester.tap(find.text('Fin de tour'));
    await tester.pumpAndSettle();

    expect(find.text('3'), findsWidgets);
  });
}
