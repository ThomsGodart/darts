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
const _bot = Player(id: 'bot', name: 'Robot', botAverage: 60);

/// Another phone sharing a game of [players], without a screen.
Future<SessionShare> _sharingPhone(
  InMemoryShareHub hub, [
  List<Player> players = const [_ann, _bob],
]) async {
  final controller = SessionController(Session(InMemoryJournal()))
    ..startGame(players);
  final share = SessionShare(hub.transport(), controller, random: Random(7));
  await share.start();
  return share;
}

Future<void> _enterTotal(WidgetTester tester, String digits) async {
  for (final digit in digits.split('')) {
    await tester.tap(find.widgetWithText(FilledButton, digit));
    await tester.pump();
  }
  await tester.tap(find.widgetWithText(FilledButton, 'OK'));
  await tester.pumpAndSettle();
}

/// From the home screen: shares a new game, and gives its code.
Future<String> _shareGame(WidgetTester tester) async {
  await launchGame(tester);
  await tester.tap(find.byKey(const Key('share-session')));
  await tester.pumpAndSettle();
  return tester
      .widget<SelectableText>(find.byKey(const Key('share-code')))
      .data!;
}

/// From the home screen: joins the session shared under [code].
Future<void> _joinFromHome(WidgetTester tester, String code) async {
  await tester.tap(find.text('Rejoindre une session'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('join-code')), code);
  await tester.pump();
  await tester.tap(find.text('Rejoindre'));
  await tester.pumpAndSettle();
}

int _remaining(SessionShare share, [int player = 0]) =>
    (share.controller.state.game! as X01Game).scores[player].remaining;

void main() {
  late InMemoryShareHub hub;

  setUp(() => hub = InMemoryShareHub());

  Future<void> pumpSharingApp(WidgetTester tester, AppStorage storage) =>
      pumpApp(tester, storage, shareTransport: hub.transport());

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

    await tester.tap(find.byKey(const Key('toggle-keyboard')));
    await tester.pump();

    expect(find.byKey(const Key('game-shell-input')), findsNothing);
    expect(find.widgetWithText(FilledButton, 'OK'), findsNothing);
    expect(find.text('501'), findsWidgets);

    await tester.tap(find.byKey(const Key('toggle-keyboard')));
    await tester.pump();
    expect(find.byKey(const Key('game-shell-input')), findsOneWidget);
  });

  group('the phone that shares', () {
    testWidgets('shows a code; what the phone that joins enters shows '
        'here', (tester) async {
      await pumpSharingApp(tester, await AppStorage.withTwoPlayers());
      final code = await _shareGame(tester);
      expect(code, hasLength(6));

      final other = await SessionShare.join(hub.transport(), code);
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
      expect(_remaining(other, 1), 441);
    });

    testWidgets('a session left while shared is shared again under its '
        'code when resumed', (tester) async {
      await pumpSharingApp(tester, await AppStorage.withTwoPlayers());
      final code = await _shareGame(tester);
      await tester.tap(find.text('Fermer'));
      await tester.pumpAndSettle();
      final other = await SessionShare.join(hub.transport(), code);

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

    testWidgets('keeps the input to itself on demand', (tester) async {
      await pumpSharingApp(tester, await AppStorage.withTwoPlayers());
      final code = await _shareGame(tester);
      final other = await SessionShare.join(hub.transport(), code);

      await tester.tap(find.byKey(const Key('share-lock-input')));
      await tester.pumpAndSettle();
      expect(other.inputLocked, isTrue);

      other.controller.submitVisitTotal(100);
      await tester.pumpAndSettle();
      expect(other.controller.events.length, 1);
    });

    testWidgets('without network, sharing says so and the game goes on', (
      tester,
    ) async {
      hub.unreachable = true;
      await pumpSharingApp(tester, await AppStorage.withTwoPlayers());
      await launchGame(tester);

      await tester.tap(find.byKey(const Key('share-session')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('share-error')), findsOneWidget);

      await tester.tap(find.text('Fermer'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('share-off-line')), findsOneWidget);
      await _enterTotal(tester, '60');
      expect(find.text('441'), findsOneWidget);

      // The network is back: the next input puts the session on the line.
      hub.unreachable = false;
      await _enterTotal(tester, '45');
      expect(find.byKey(const Key('share-off-line')), findsNothing);
    });

    testWidgets('says when the network drops, until it is back', (
      tester,
    ) async {
      await pumpSharingApp(tester, await AppStorage.withTwoPlayers());
      final code = await _shareGame(tester);
      await tester.tap(find.text('Fermer'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('share-off-line')), findsNothing);

      hub.cut(code);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('share-off-line')), findsOneWidget);

      hub.cut(code, off: false);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('share-off-line')), findsNothing);
    });

    testWidgets('starting a new session tells the guests of the one it '
        'ends', (tester) async {
      await pumpSharingApp(tester, await AppStorage.withTwoPlayers());
      final code = await _shareGame(tester);
      await tester.tap(find.text('Fermer'));
      await tester.pumpAndSettle();
      final other = await SessionShare.join(hub.transport(), code);
      for (final total in [180, 0, 180, 0]) {
        other.controller.submitVisitTotal(total);
      }
      other.controller.submitVisitTotal(141, dartsAtCheckout: 3);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('leave-game')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nouvelle session'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Terminer et commencer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lancer la partie'));
      await tester.pumpAndSettle();

      expect(other.controller.state.isEnded, isTrue);
      // The new session is not shared until asked.
      expect(hub.linesOn(code), 1);
    });
  });

  group('the phone that joins', () {
    testWidgets('opens the shared game as a screen, and its keyboard '
        'comes back on demand', (tester) async {
      final host = await _sharingPhone(hub);
      host.controller.submitVisitTotal(41);

      await pumpSharingApp(tester, AppStorage());
      await _joinFromHome(tester, host.code!);

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
      expect(_remaining(host), 400);
    });

    testWidgets('shows how a game ended, but does not end the session', (
      tester,
    ) async {
      final host = await _sharingPhone(hub);
      await pumpSharingApp(tester, AppStorage());
      await _joinFromHome(tester, host.code!);

      for (final total in [180, 0, 180, 0]) {
        host.controller.submitVisitTotal(total);
      }
      host.controller.submitVisitTotal(141, dartsAtCheckout: 3);
      await tester.pumpAndSettle();

      expect(find.text('Ann gagne !'), findsOneWidget);
      expect(find.text('Rejouer'), findsOneWidget);
      expect(find.text('Terminer la session'), findsNothing);
    });

    testWidgets('is only a screen once the phone that shares keeps the '
        'input', (tester) async {
      final host = await _sharingPhone(hub);
      await pumpSharingApp(tester, AppStorage());
      await _joinFromHome(tester, host.code!);
      expect(find.byKey(const Key('toggle-keyboard')), findsOneWidget);

      host.lockInput(true);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('toggle-keyboard')), findsNothing);
      expect(find.byKey(const Key('game-shell-input')), findsNothing);

      for (final total in [180, 0, 180, 0]) {
        host.controller.submitVisitTotal(total);
      }
      host.controller.submitVisitTotal(141, dartsAtCheckout: 3);
      await tester.pumpAndSettle();
      expect(find.text('Ann gagne !'), findsOneWidget);
      expect(find.text('Rejouer'), findsNothing);
    });

    testWidgets('leaves the virtual opponent to the phone that shares, '
        'and throws for it only when that one does not', (tester) async {
      final host = await _sharingPhone(hub, const [_bot, _ann]);
      await pumpSharingApp(tester, AppStorage());
      await _joinFromHome(tester, host.code!);
      expect(host.controller.events.length, 1);

      // Long enough for the phone that shares to have thrown.
      await tester.pump(const Duration(seconds: 2));
      expect(host.controller.events.length, 1);

      // It did not: this phone does.
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(host.controller.events.length, 2);
      expect(host.controller.state.game!.activePlayer.name, 'Ann');
    });

    testWidgets('says when the network drops', (tester) async {
      final host = await _sharingPhone(hub);
      await pumpSharingApp(tester, AppStorage());
      await _joinFromHome(tester, host.code!);

      hub.cut(host.code!);
      await tester.pumpAndSettle();

      expect(
        find.text('Connexion perdue : le score peut ne plus être à jour.'),
        findsOneWidget,
      );
    });

    testWidgets('a code nobody shares is refused in the dialog, which '
        'only Annuler closes', (tester) async {
      await pumpSharingApp(tester, AppStorage());
      await tester.tap(find.text('Rejoindre une session'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('join-code')), '123456');
      await tester.pump();
      await tester.tap(find.text('Rejoindre'));
      await tester.pump();

      // While it joins, a tap outside does not close it.
      await tester.tapAt(const Offset(5, 5));
      await tester.pump(const Duration(seconds: 7));
      await tester.pumpAndSettle();

      expect(
        find.text('Aucune session partagée sous ce code.'),
        findsOneWidget,
      );
      expect(hub.linesOn('123456'), 0);
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(find.text('Nouvelle session'), findsOneWidget);
    });

    testWidgets('once left, the session can be kept in this phone\'s '
        'history, its people told apart', (tester) async {
      final host = await _sharingPhone(hub);
      host.controller.submitVisitTotal(41);
      await pumpSharingApp(tester, await AppStorage.withPlayers(['Ann']));
      await _joinFromHome(tester, host.code!);

      await tester.tap(find.byKey(const Key('leave-game')));
      await tester.pumpAndSettle();
      expect(find.text('Garder cette session ?'), findsOneWidget);
      // Ann is known here; Bob is not.
      expect(find.text('Nouveau joueur'), findsOneWidget);

      await tester.tap(find.text('Garder'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Historique'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Ann'), findsWidgets);
      expect(find.textContaining('Bob'), findsWidgets);
    });

    testWidgets('two people said to be the same player cannot be kept; '
        'not kept, the session leaves no trace', (tester) async {
      final host = await _sharingPhone(hub);
      host.controller.submitVisitTotal(41);
      await pumpSharingApp(tester, await AppStorage.withPlayers(['Ann']));
      await _joinFromHome(tester, host.code!);
      await tester.tap(find.byKey(const Key('leave-game')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('keep-as-b')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ann').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('keep-clash')), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed,
        isNull,
      );

      await tester.tap(find.text('Ne pas garder'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Historique'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Bob'), findsNothing);
    });

    testWidgets('a session ended on the phone that shares closes the '
        'game here', (tester) async {
      final host = await _sharingPhone(hub);
      await pumpSharingApp(tester, AppStorage());
      await _joinFromHome(tester, host.code!);

      host.controller.endSession();
      await tester.pumpAndSettle();

      expect(find.text('Nouvelle session'), findsOneWidget);
      expect(hub.linesOn(host.code!), 1);
    });
  });
}
