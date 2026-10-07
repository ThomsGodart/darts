import 'package:darts_points_counter/session/session.dart';
import 'package:darts_points_counter/session_launcher.dart';
import 'package:darts_points_counter/share/share_transport.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late InMemoryShareHub hub;
  late SessionLauncher launcher;
  late GameSetup setup;
  late InMemoryPlayerCatalog catalog;

  setUp(() async {
    hub = InMemoryShareHub();
    catalog = InMemoryPlayerCatalog();
    setup = (
      players: [await catalog.add('Ana'), await catalog.add('Bob')],
      config: const X01Config(),
    );
    launcher = SessionLauncher(
      InMemorySessionRepository(),
      catalog,
      shareTransport: hub.transport(),
    );
  });

  test('without a transport there is nothing to share', () async {
    final offline = SessionLauncher(InMemorySessionRepository(), catalog);
    final session = await offline.newGame(setup);

    expect(offline.canShare, isFalse);
    expect(offline.shareOf(session), isNull);
  });

  test('a session is not shared until asked', () async {
    final share = launcher.shareOf(await launcher.newGame(setup))!;
    await _settle();

    expect(launcher.canShare, isTrue);
    expect(share.isOn, isFalse);
    expect(share.isWanted, isFalse);
  });

  test('left while shared, a session is back on the line as it was when '
      'it is opened again', () async {
    final session = await launcher.newGame(setup);
    final share = launcher.shareOf(session)!;
    await share.start();
    share.lockInput(true);
    final code = share.code!;
    launcher.closeShare(share);
    expect(hub.linesOn(code), 0);

    final again = launcher.shareOf((await launcher.resume())!)!;
    await _settle();

    expect(again.isOn, isTrue);
    expect(again.code, code);
    expect(again.inputLocked, isTrue);
  });

  test('left while the network kept it off the line, a share is still '
      'wanted, under its code', () async {
    final session = await launcher.newGame(setup);
    final share = launcher.shareOf(session)!;
    await share.start();
    final code = share.code!;
    launcher.closeShare(share);

    hub.unreachable = true;
    final offLine = launcher.shareOf(session)!;
    await _settle();
    expect(offLine.isOffLine, isTrue);
    launcher.closeShare(offLine);

    hub.unreachable = false;
    final back = launcher.shareOf(session)!;
    await _settle();
    expect(back.isOn, isTrue);
    expect(back.code, code);
  });

  test('a share that was stopped stays stopped', () async {
    final session = await launcher.newGame(setup);
    final share = launcher.shareOf(session)!;
    await share.start();
    share.stop();
    launcher.closeShare(share);

    final again = launcher.shareOf(session)!;
    await _settle();
    expect(again.isOn, isFalse);
    expect(again.code, isNull);
  });

  test('a new session is not shared, and the guests of the one it ends '
      'are told', () async {
    final session = await launcher.newGame(setup);
    final share = launcher.shareOf(session)!;
    await share.start();
    final guest = await launcher.join(share.code!);
    launcher.closeShare(share);

    final next = launcher.shareOf(await launcher.newGame(setup))!;
    await _settle();

    expect(guest.controller.state.isEnded, isTrue);
    expect(next.isOn, isFalse);
  });

  test('joining gives a guest holding the game', () async {
    final session = await launcher.newGame(setup);
    final share = launcher.shareOf(session)!;
    await share.start();
    session.submitVisitTotal(60);

    final guest = await launcher.join(share.code!);

    expect(guest.isGuest, isTrue);
    expect(guest.controller.events.length, 2);
    launcher.closeShare(guest);
    expect(hub.linesOn(share.code!), 1);
  });
}
