import 'dart:math';

import 'package:darts_points_counter/session/session.dart';
import 'package:darts_points_counter/session_controller.dart';
import 'package:darts_points_counter/share/session_share.dart';
import 'package:darts_points_counter/share/share_transport.dart';
import 'package:flutter_test/flutter_test.dart';

const _ann = Player(id: 'a', name: 'Ann');
const _bob = Player(id: 'b', name: 'Bob');

/// A device: its own controller, on its own end of the hub.
class _Device {
  _Device(InMemoryShareHub hub, {String? code, int seed = 1})
    : controller = SessionController(Session(journal)) {
    share = SessionShare(
      hub.transport(),
      controller,
      code: code,
      random: Random(seed),
    );
  }

  static InMemoryJournal journal = InMemoryJournal();

  final SessionController controller;
  late final SessionShare share;

  int get remaining => (controller.state.game! as X01Game).scores[0].remaining;
}

_Device _device(InMemoryShareHub hub, {String? code, int seed = 1}) {
  _Device.journal = InMemoryJournal();
  return _Device(hub, code: code, seed: seed);
}

/// Lets the messages in flight arrive.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late InMemoryShareHub hub;
  late _Device host;
  late _Device guest;

  setUp(() async {
    hub = InMemoryShareHub();
    host = _device(hub)..controller.startGame([_ann, _bob]);
    guest = _device(hub, seed: 2);
    await host.share.start();
  });

  test('a started share has a code of six digits', () {
    expect(host.share.isOn, isTrue);
    expect(host.share.code, matches(RegExp(r'^\d{6}$')));
  });

  test('a device that joins gets the game as it stands', () async {
    host.controller.submitVisitTotal(60);
    await guest.share.join(host.share.code!);

    expect(guest.remaining, 441);
    expect(guest.controller.state.game!.activePlayer.name, 'Bob');
    await _settle();
    expect(host.share.joinedCount, 1);
  });

  test('what one device enters shows on the other, both ways', () async {
    await guest.share.join(host.share.code!);

    host.controller.submitVisitTotal(100);
    await _settle();
    expect(guest.remaining, 401);

    guest.controller.submitVisitTotal(26);
    await _settle();
    expect((host.controller.state.game! as X01Game).scores[1].remaining, 475);
  });

  test('an undo and a cancelled game cross the line too', () async {
    await guest.share.join(host.share.code!);
    host.controller.submitVisitTotal(100);
    await _settle();

    guest.controller.undo();
    await _settle();
    expect(host.remaining, 501);

    host.controller.cancelGame();
    await _settle();
    expect(guest.controller.state.game, isNull);
  });

  test('joining a code nobody shares fails', () async {
    await expectLater(
      guest.share.join('000000', timeout: const Duration(milliseconds: 50)),
      throwsA(isA<NoSuchShare>()),
    );
    expect(guest.share.isOn, isFalse);
  });

  test('without network, starting and joining say so', () async {
    hub.unreachable = true;
    final other = _device(hub)..controller.startGame([_ann, _bob]);

    await expectLater(other.share.start(), throwsA(isA<ShareUnreachable>()));
    await expectLater(
      guest.share.join('123456'),
      throwsA(isA<ShareUnreachable>()),
    );
    expect(other.share.isOn, isFalse);
  });

  test('two inputs at once: both devices end on the same one', () async {
    await guest.share.join(host.share.code!);

    host.controller.submitVisitTotal(100);
    guest.controller.submitVisitTotal(26);
    await _settle();
    await _settle();
    await _settle();

    expect(host.remaining, guest.remaining);
    expect(host.controller.events.length, 2);
    expect(guest.controller.events.length, 2);
  });

  test('a device back on the line catches up with what it missed', () async {
    await guest.share.join(host.share.code!);
    guest.share.stop();
    host.controller.submitVisitTotal(100);
    host.controller.submitVisitTotal(60);
    await _settle();
    expect(guest.remaining, 501);

    // Its line reopened under the same code, as after a network drop.
    await guest.share.start();
    await _settle();
    await _settle();
    expect(guest.remaining, 401);
    expect(guest.controller.events.length, 3);
  });

  test('a missed message is caught up with on the next one', () async {
    await guest.share.join(host.share.code!);
    await _settle();
    // The guest's line drops a message without knowing.
    guest.share.stop();
    host.controller.submitVisitTotal(100);
    await _settle();
    await guest.share.start();
    await _settle();
    await _settle();

    host.controller.submitVisitTotal(60);
    await _settle();
    await _settle();
    expect(guest.controller.events.length, 3);
  });

  test('the host coming back under its code takes what was played '
      'without it', () async {
    await guest.share.join(host.share.code!);
    final code = host.share.code!;
    host.share.stop();
    guest.controller.submitVisitTotal(45);
    await _settle();
    expect(host.remaining, 501);

    // The game screen reopened: a new share on the same session.
    final back = SessionShare(
      hub.transport(),
      host.controller,
      code: code,
      random: Random(3),
    );
    await back.start();
    await _settle();
    await _settle();

    expect(back.code, code);
    expect(host.remaining, 456);
  });

  test('a stopped share sends nothing more', () async {
    await guest.share.join(host.share.code!);
    host.share.stop();

    host.controller.submitVisitTotal(100);
    await _settle();
    expect(guest.remaining, 501);
    expect(host.share.code, isNotNull);
  });

  test('nonsense on the line is ignored', () async {
    await guest.share.join(host.share.code!);
    final line = await hub.transport().open(host.share.code!);

    line
      ..send({
        'kind': 'journal',
        'rev': 99,
        'origin': 'x',
        'from': 'x',
        'events': ['{"t":"dart_thrown","p":{"sector":77,"multiplier":9}}'],
      })
      ..send({'kind': 'delta', 'rev': 'many'})
      ..send({'hello': 'world'});
    await _settle();

    expect(host.remaining, 501);
    expect(host.controller.events.length, 1);
    host.controller.submitVisitTotal(100);
    await _settle();
    await _settle();
    expect(guest.remaining, 401);
  });

  test('the times the events were recorded at survive a journal that '
      'changes nothing', () async {
    final journal = InMemoryJournal(now: () => DateTime(2026, 1, 1));
    final session = Session(journal)..startGame([_ann, _bob]);
    final before = journal.recordedAt.single;

    expect(session.rewrite(1, const []), isA<Accepted>());
    expect(journal.recordedAt.single, before);
    expect(session.rewrite(2, const []), isA<Rejected>());
  });
}
