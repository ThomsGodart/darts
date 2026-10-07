import 'dart:async';
import 'dart:math';

import 'package:darts_points_counter/session/session.dart';
import 'package:darts_points_counter/session_controller.dart';
import 'package:darts_points_counter/share/session_share.dart';
import 'package:darts_points_counter/share/share_protocol.dart';
import 'package:darts_points_counter/share/share_transport.dart';
import 'package:flutter_test/flutter_test.dart';

const _ann = Player(id: 'a', name: 'Ann');
const _bob = Player(id: 'b', name: 'Bob');

/// Lets the messages in flight arrive, and their answers too.
Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

int _remaining(SessionShare share, [int player = 0]) =>
    (share.controller.state.game! as X01Game).scores[player].remaining;

/// A device that is not the app: says what it likes on the line, and
/// keeps what it hears.
class _Stranger {
  _Stranger(this.line) {
    line.messages.listen((m) => heard.add(ShareSignal.fromWire(m)));
  }

  static Future<_Stranger> on(InMemoryShareHub hub, String code) async =>
      _Stranger(await hub.transport().open(code));

  final ShareLine line;
  final heard = <ShareSignal>[];

  void say(ShareSignal signal) => line.send(signal.toWire());
}

/// A transport whose lines open when the test says.
class _SlowTransport implements ShareTransport {
  _SlowTransport(this._inner);

  final ShareTransport _inner;
  final opening = Completer<void>();
  int opened = 0;

  @override
  Future<ShareLine> open(String code) async {
    await opening.future;
    opened++;
    return _inner.open(code);
  }
}

void main() {
  late InMemoryShareHub hub;
  late SessionController hostSession;
  late SessionShare host;
  late String code;

  Future<SessionShare> join() =>
      SessionShare.join(hub.transport(), code, random: Random(2));

  setUp(() async {
    hub = InMemoryShareHub();
    hostSession = SessionController(Session(InMemoryJournal()))
      ..startGame([_ann, _bob]);
    host = SessionShare(hub.transport(), hostSession, random: Random(1));
    await host.start();
    code = host.code!;
  });

  group('sharing and joining', () {
    test('a started share has a code of six digits', () {
      expect(host.isOn, isTrue);
      expect(host.isWanted, isTrue);
      expect(code, matches(RegExp(r'^\d{6}$')));
    });

    test('a device that joins gets the game as it stands', () async {
      hostSession.submitVisitTotal(60);
      final guest = await join();

      expect(guest.isGuest, isTrue);
      expect(_remaining(guest), 441);
      expect(guest.controller.state.game!.activePlayer.name, 'Bob');
      await _settle();
      expect(host.joinedCount, 1);
    });

    test('what one device enters shows on the other, both ways', () async {
      final guest = await join();

      hostSession.submitVisitTotal(100);
      await _settle();
      expect(_remaining(guest), 401);

      guest.controller.submitVisitTotal(26);
      await _settle();
      expect(_remaining(host, 1), 475);
    });

    test('an undo and a cancelled game cross the line too', () async {
      final guest = await join();
      hostSession.submitVisitTotal(100);
      await _settle();

      guest.controller.undo();
      await _settle();
      expect(_remaining(host), 501);

      hostSession.cancelGame();
      await _settle();
      expect(guest.controller.state.game, isNull);
    });

    test('joining a code nobody shares fails, the line closed', () async {
      await expectLater(
        SessionShare.join(
          hub.transport(),
          '000000',
          timeout: const Duration(milliseconds: 50),
        ),
        throwsA(isA<NoSuchShare>()),
      );
      expect(hub.linesOn('000000'), 0);
    });

    test('without network, starting and joining say so', () async {
      hub.unreachable = true;
      final other = SessionShare(hub.transport(), hostSession);

      await expectLater(other.start(), throwsA(isA<ShareUnreachable>()));
      await expectLater(join(), throwsA(isA<ShareUnreachable>()));
      expect(other.isOn, isFalse);
      // Still wanted: it is off the line for want of a network.
      expect(other.isOffLine, isTrue);
    });

    test('a stopped share sends nothing more, and keeps its code', () async {
      final guest = await join();
      host.stop();

      hostSession.submitVisitTotal(100);
      await _settle();
      expect(_remaining(guest), 501);
      expect(host.code, code);
      expect(host.isWanted, isFalse);
      expect(host.isOffLine, isFalse);
    });

    test('starting twice at once opens one line', () async {
      final transport = _SlowTransport(hub.transport());
      final share = SessionShare(transport, hostSession, random: Random(5));

      final both = Future.wait([share.start(), share.start()]);
      transport.opening.complete();
      await both;

      expect(transport.opened, 1);
    });

    test('a share disposed of while its line opens leaves none open', () async {
      final transport = _SlowTransport(hub.transport());
      final share = SessionShare(transport, hostSession, code: '424242');

      final started = share.start();
      share.dispose();
      transport.opening.complete();
      await started;
      await _settle();

      expect(hub.linesOn('424242'), 0);
    });
  });

  group('catching up', () {
    test('two inputs at once: both devices end on the same one', () async {
      final guest = await join();

      hostSession.submitVisitTotal(100);
      guest.controller.submitVisitTotal(26);
      await _settle();

      expect(_remaining(host), _remaining(guest));
      expect(hostSession.events.length, 2);
      expect(guest.controller.events.length, 2);
    });

    test('a device cut off sees it, and catches up once back', () async {
      final guest = await join();
      hub.cut(code);
      await _settle();
      expect(guest.isOffLine, isTrue);
      expect(host.isOffLine, isTrue);

      hostSession.submitVisitTotal(100);
      hostSession.submitVisitTotal(60);
      await _settle();
      expect(_remaining(guest), 501);

      hub.cut(code, off: false);
      await _settle();
      expect(guest.isOffLine, isFalse);
      expect(guest.controller.events.length, 3);
      expect(_remaining(guest), 401);
    });

    test('what a guest entered while cut off reaches the others', () async {
      final guest = await join();
      hub.cut(code);
      guest.controller.submitVisitTotal(45);
      await _settle();
      expect(_remaining(host), 501);

      hub.cut(code, off: false);
      await _settle();
      expect(_remaining(host), 456);
    });

    test('the device that shares, back under its code, takes what was '
        'played without it', () async {
      final guest = await join();
      host.dispose();
      guest.controller.submitVisitTotal(45);
      await _settle();

      // The game screen reopened: a new share on the same session.
      final back = SessionShare(
        hub.transport(),
        hostSession,
        code: code,
        random: Random(3),
      );
      await back.start();
      await _settle();

      expect(back.code, code);
      expect(_remaining(back), 456);
    });

    test('a device that says it is ahead is asked for its journal', () async {
      final stranger = await _Stranger.on(hub, code);
      stranger.say(const Hello(from: 'x', version: (rev: 50, origin: 'x')));
      await _settle();

      expect(stranger.heard.single, isA<Hello>());
    });

    test('an older journal is answered with the one that stands', () async {
      hostSession.submitVisitTotal(60);
      final stranger = await _Stranger.on(hub, code);
      stranger.say(
        const WholeJournal(
          from: 'x',
          version: (rev: 1, origin: '0'),
          events: [],
        ),
      );
      await _settle();

      final answer = stranger.heard.single as WholeJournal;
      expect(answer.events, hasLength(2));
      expect(hostSession.events, hasLength(2));
    });

    test('a change built on an old version is answered with the journal '
        'that stands', () async {
      hostSession.submitVisitTotal(60);
      final stranger = await _Stranger.on(hub, code);
      stranger.say(
        const JournalChange(
          from: 'x',
          version: (rev: 1, origin: '0'),
          base: (rev: 0, origin: ''),
          keep: 0,
          tail: [],
        ),
      );
      await _settle();

      expect(stranger.heard.single, isA<WholeJournal>());
      expect(hostSession.events, hasLength(2));
    });
  });

  group('what the device that shares does not take', () {
    test('nonsense on the line is ignored', () async {
      final guest = await join();
      final stranger = await _Stranger.on(hub, code);

      stranger.line
        ..send({
          'v': 1,
          'kind': 'journal',
          'rev': 99,
          'origin': 'x',
          'from': 'x',
          'events': ['{"t":"dart_thrown","p":{"sector":77,"multiplier":9}}'],
        })
        ..send({'v': 1, 'kind': 'delta', 'rev': 'many'})
        ..send({
          'v': 1,
          'kind': 'journal',
          'rev': 99,
          'origin': 'x',
          'from': 'x',
          'events': ['x' * (ShareSignal.maxEventLength + 1)],
        })
        ..send({'hello': 'world'});
      await _settle();

      expect(hostSession.events.length, 1);
      hostSession.submitVisitTotal(100);
      await _settle();
      expect(_remaining(guest), 401);
      expect(_remaining(host), 401);
    });

    test('games already played cannot be rewritten from the line', () async {
      hostSession
        ..submitVisitTotal(180)
        ..submitVisitTotal(0)
        ..submitVisitTotal(180)
        ..submitVisitTotal(0)
        ..submitVisitTotal(141, dartsAtCheckout: 3)
        ..rematch();
      final guest = await join();
      final played = hostSession.events.length;
      final stranger = await _Stranger.on(hub, code);

      stranger.say(
        const WholeJournal(
          from: 'x',
          version: (rev: 9000, origin: 'x'),
          events: [],
        ),
      );
      await _settle();

      expect(hostSession.events.length, played);
      expect(hostSession.state.games.length, 2);
      // The guest, who took the empty journal, is given the real one back.
      expect(guest.controller.events.length, played);
    });

    test('once the input is locked, a guest is a screen: what it enters '
        'does not stand', () async {
      final guest = await join();
      host.lockInput(true);
      await _settle();
      expect(guest.inputLocked, isTrue);

      guest.controller.submitVisitTotal(26);
      await _settle();
      expect(hostSession.events.length, 1);
      expect(guest.controller.events.length, 1);

      host.lockInput(false);
      await _settle();
      expect(guest.inputLocked, isFalse);
      guest.controller.submitVisitTotal(26);
      await _settle();
      expect(hostSession.events.length, 2);
    });

    test('a guest joining a locked share knows at once', () async {
      host.lockInput(true);
      final guest = await join();
      expect(guest.inputLocked, isTrue);
    });
  });

  group('other builds, and the end', () {
    test('a message of another protocol is not read, and is told', () async {
      final stranger = await _Stranger.on(hub, code);
      stranger.line.send({'v': 2, 'kind': 'journal', 'rev': 99});
      await _settle();

      expect(host.hasIncompatiblePeer, isTrue);
      expect(hostSession.events.length, 1);
    });

    test('joining a share of another protocol says so', () async {
      host.dispose();
      final old = await hub.transport().open(code);
      old.messages.listen((_) => old.send({'kind': 'journal', 'rev': 4}));

      await expectLater(
        SessionShare.join(
          hub.transport(),
          code,
          timeout: const Duration(milliseconds: 50),
        ),
        throwsA(isA<IncompatibleShare>()),
      );
    });

    test('guests are told when the session is ended away from the '
        'line', () async {
      final guest = await join();
      host.dispose();

      await SessionShare.announceGone(hub.transport(), code);
      await _settle();

      expect(guest.controller.state.isEnded, isTrue);
      expect(hostSession.state.isEnded, isFalse);
    });

    test(
      'the device that keeps the session does not end it on hearsay',
      () async {
        final stranger = await _Stranger.on(hub, code);
        stranger.say(const SessionGone(from: 'x'));
        await _settle();
        expect(hostSession.state.isEnded, isFalse);
      },
    );

    test('too large a journal is not a signal', () {
      ShareMessage journal(List<String> events) =>
          WholeJournal(from: 'a', version: noJournal, events: events).toWire();

      expect(
        () => ShareSignal.fromWire(
          journal(['x' * (ShareSignal.maxEventLength + 1)]),
        ),
        throwsFormatException,
      );
      expect(
        () => ShareSignal.fromWire(
          journal(List.filled(ShareSignal.maxEvents + 1, 'e')),
        ),
        throwsFormatException,
      );
      expect(ShareSignal.fromWire(journal(['e'])), isA<WholeJournal>());
    });

    test('a session ended on one device is ended on the others', () async {
      final guest = await join();
      hostSession.endSession();
      await _settle();
      expect(guest.controller.state.isEnded, isTrue);
    });

    test('signals survive the wire', () {
      const signals = <ShareSignal>[
        Hello(from: 'a', locked: true, version: (rev: 3, origin: 'a')),
        WholeJournal(
          from: 'a',
          version: (rev: 3, origin: 'a'),
          events: ['e1', 'e2'],
        ),
        JournalChange(
          from: 'b',
          locked: false,
          version: (rev: 4, origin: 'b'),
          base: (rev: 3, origin: 'a'),
          keep: 1,
          tail: ['e3'],
        ),
        SessionGone(from: 'a'),
      ];
      for (final signal in signals) {
        final back = ShareSignal.fromWire(signal.toWire());
        expect(back.toWire(), signal.toWire());
        expect(back.runtimeType, signal.runtimeType);
      }
    });
  });

  test('the times the events were recorded at survive a journal that '
      'changes nothing', () {
    final journal = InMemoryJournal(now: () => DateTime(2026, 1, 1));
    final session = Session(journal)..startGame([_ann, _bob]);
    final before = journal.recordedAt.single;

    expect(session.rewrite(1, const []), isA<Accepted>());
    expect(journal.recordedAt.single, before);
    expect(session.rewrite(2, const []), isA<Rejected>());
  });
}
