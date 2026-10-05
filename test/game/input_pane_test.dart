import 'package:darts_points_counter/game/input_pane.dart';
import 'package:darts_points_counter/session/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpPane(WidgetTester tester, InputPane pane) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: pane)));

void main() {
  testWidgets('shows the visit so far and takes its end and its undo', (
    tester,
  ) async {
    final calls = <String>[];
    await pumpPane(
      tester,
      InputPane(
        dartsInVisit: const [Dart.treble(20)],
        onUndo: () => calls.add('undo'),
        onEndVisit: () => calls.add('end'),
        children: const [],
      ),
    );

    expect(
      tester.widget<Text>(find.byKey(const Key('darts-in-visit'))).data,
      'T20  ·  –  ·  –',
    );
    await tester.tap(find.text('Fin de tour'));
    await tester.tap(find.byTooltip('Annuler la saisie'));
    expect(calls, ['end', 'undo']);
  });

  testWidgets('without a visit to end or an input to undo, offers neither', (
    tester,
  ) async {
    await pumpPane(
      tester,
      const InputPane(
        onUndo: null,
        secondaryAction: Text('autre'),
        children: [],
      ),
    );

    expect(find.byKey(const Key('darts-in-visit')), findsNothing);
    expect(find.text('Fin de tour'), findsNothing);
    expect(find.text('autre'), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(find.byKey(const Key('undo'))).onPressed,
      isNull,
    );
  });

  testWidgets('the sector grid only takes enabled sectors', (tester) async {
    final tapped = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SectorGrid(
            labelOf: (sector) => 'D$sector',
            onSector: tapped.add,
            isEnabled: (sector) => sector != 7,
          ),
        ),
      ),
    );

    await tester.tap(find.text('D7'));
    await tester.tap(find.text('D20'));
    expect(tapped, [20]);
  });
}
