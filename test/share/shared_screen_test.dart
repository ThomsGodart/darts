import 'dart:math';

import 'package:darts_points_counter/session/session.dart';
import 'package:darts_points_counter/session_controller.dart';
import 'package:darts_points_counter/share/session_share.dart';
import 'package:darts_points_counter/share/share_transport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_test_harness.dart';

const _ann = Player(id: 'a', name: 'Ann');
const _bob = Player(id: 'b', name: 'Bob');

/// The other phone: a session on the hub, without a screen.
({SessionController controller, SessionShare share}) _otherPhone(
  InMemoryShareHub hub,
) {
  final controller = SessionController(Session(InMemoryJournal()));
  return (
    controller: controller,
    share: SessionShare(hub.transport(), controller, random: Random(7)),
  );
}

Future<void> _enterTotal(WidgetTester tester, String digits) async {
  for (final digit in digits.split('')) {
    await tester.tap(find.widgetWithText(FilledButton, digit));
    await tester.pump();
  }
  await tester.tap(find.widgetWithText(FilledButton, 'OK'));
  await tester.pumpAndSettle();
}

void main() {
  late InMemoryShareHub hub;

  setUp(() => hub = InMemoryShareHub());

  testWidgets('without a transport, nothing offers to share or join', (
    tester,
  ) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    expect(find.text('Rejoindre une session'), findsNothing);

    await launchGame(tester);
    expect(find.byKey(const Key('share-session')), findsNothing);
  });

  testWidgets('the keyboard can be put away, the game taking the screen', (
    tester,
  ) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await launchGame(tester);
    final boardHeight = tester
        .getSize(find.byKey(const Key('game-shell-state')))
        .height;

    await tester.tap(find.byKey(const Key('toggle-keyboard')));
    await tester.pump();

    expect(find.byKey(const Key('game-shell-input')), findsNothing);
    expect(find.text('Valider'), findsNothing);
    expect(find.text('501'), findsWidgets);
    expect(boardHeight, lessThan(1000));

    await tester.tap(find.byKey(const Key('toggle-keyboard')));
    await tester.pump();
    expect(find.byKey(const Key('game-shell-input')), findsOneWidget);
  });

  testWidgets('sharing shows a code; what the phone that joins enters '
      'shows here', (tester) async {
    await pumpApp(
      tester,
      await AppStorage.withTwoPlayers(),
      shareTransport: hub.transport(),
    );
    await launchGame(tester);

    await tester.tap(find.byKey(const Key('share-session')));
    await tester.pumpAndSettle();
    final code = tester
        .widget<SelectableText>(find.byKey(const Key('share-code')))
        .data!;
    expect(code, hasLength(6));

    final other = _otherPhone(hub);
    await other.share.join(code);
    await tester.pump();
    expect(find.text('1 appareil a rejoint'), findsOneWidget);
    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();

    other.controller.submitVisitTotal(100);
    await tester.pump();
    await tester.pump();
    expect(find.text('401'), findsOneWidget);

    await _enterTotal(tester, '60');
    await tester.pump();
    expect((other.controller.state.game! as X01Game).scores[1].remaining, 441);
  });

  testWidgets('a session left while shared is shared again under its code '
      'when resumed', (tester) async {
    await pumpApp(
      tester,
      await AppStorage.withTwoPlayers(),
      shareTransport: hub.transport(),
    );
    await launchGame(tester);
    await tester.tap(find.byKey(const Key('share-session')));
    await tester.pumpAndSettle();
    final code = tester
        .widget<SelectableText>(find.byKey(const Key('share-code')))
        .data!;
    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();
    final other = _otherPhone(hub);
    await other.share.join(code);

    // The game is finished from the other phone, then left here.
    for (final total in [180, 0, 180, 0]) {
      other.controller.submitVisitTotal(total);
    }
    other.controller.submitVisitTotal(141, dartsAtCheckout: 3);
    await tester.pumpAndSettle();
    expect(find.text('Joueur 1 gagne !'), findsOneWidget);
    await tester.tap(find.byKey(const Key('leave-game')));
    await tester.pumpAndSettle();

    // Meanwhile the other phone plays on.
    other.controller.rematch();
    other.controller.submitVisitTotal(45);
    await tester.pump();

    await tester.tap(find.text('Reprendre la session'));
    await tester.pumpAndSettle();
    expect(find.text('456'), findsOneWidget);
    await tester.tap(find.byKey(const Key('share-session')));
    await tester.pumpAndSettle();
    expect(find.text(code), findsOneWidget);
  });

  testWidgets('joining opens the shared game as a screen, and the '
      'keyboard comes back on demand', (tester) async {
    final host = _otherPhone(hub);
    host.controller.startGame([_ann, _bob]);
    host.controller.submitVisitTotal(41);
    await host.share.start();

    await pumpApp(tester, AppStorage(), shareTransport: hub.transport());
    await tester.tap(find.text('Rejoindre une session'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('join-code')),
      host.share.code!,
    );
    await tester.pump();
    await tester.tap(find.text('Rejoindre'));
    await tester.pumpAndSettle();

    expect(find.text('460'), findsOneWidget);
    expect(find.text('Ann'), findsWidgets);
    expect(find.byKey(const Key('game-shell-input')), findsNothing);

    host.controller.submitVisitTotal(100);
    await tester.pump();
    await tester.pump();
    expect(find.text('401'), findsOneWidget);

    await tester.tap(find.byKey(const Key('toggle-keyboard')));
    await tester.pump();
    await switchToTotals(tester);
    await _enterTotal(tester, '60');
    await tester.pump();
    expect((host.controller.state.game! as X01Game).scores[0].remaining, 400);
  });

  testWidgets('a code nobody shares is refused in the dialog', (tester) async {
    await pumpApp(tester, AppStorage(), shareTransport: hub.transport());
    await tester.tap(find.text('Rejoindre une session'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('join-code')), '123456');
    await tester.pump();
    await tester.tap(find.text('Rejoindre'));
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();

    expect(find.text('Aucune session partagée sous ce code.'), findsOneWidget);
    expect(find.text('Rejoindre une session'), findsWidgets);
  });

  testWidgets('without network, sharing says so and the game goes on', (
    tester,
  ) async {
    hub.unreachable = true;
    await pumpApp(
      tester,
      await AppStorage.withTwoPlayers(),
      shareTransport: hub.transport(),
    );
    await launchGame(tester);

    await tester.tap(find.byKey(const Key('share-session')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('share-error')), findsOneWidget);

    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();
    await _enterTotal(tester, '60');
    expect(find.text('441'), findsOneWidget);
  });

  testWidgets('a session ended on the other phone closes the game here', (
    tester,
  ) async {
    final host = _otherPhone(hub);
    host.controller.startGame([_ann, _bob]);
    await host.share.start();
    await pumpApp(tester, AppStorage(), shareTransport: hub.transport());
    await tester.tap(find.text('Rejoindre une session'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('join-code')),
      host.share.code!,
    );
    await tester.pump();
    await tester.tap(find.text('Rejoindre'));
    await tester.pumpAndSettle();

    host.controller.endSession();
    await tester.pumpAndSettle();

    expect(find.text('Nouvelle session'), findsOneWidget);
  });
}
