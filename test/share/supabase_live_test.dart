// Talks to the real Supabase project: left out of the suite unless asked.
//
//   flutter test --dart-define=LIVE_SHARE=true test/share/supabase_live_test.dart
import 'package:darts_points_counter/backend.dart';
import 'package:darts_points_counter/session/session.dart';
import 'package:darts_points_counter/session_controller.dart';
import 'package:darts_points_counter/share/session_share.dart';
import 'package:flutter_test/flutter_test.dart';

const _live = bool.fromEnvironment('LIVE_SHARE');

/// Polls until [reached], for as long as a message may take on a network.
Future<void> _until(bool Function() reached) async {
  for (var i = 0; i < 100 && !reached(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  expect(reached(), isTrue);
}

void main() {
  test(
    'two devices share a session through the Supabase project',
    () async {
      final session = SessionController(Session(InMemoryJournal()))
        ..startGame(const [
          Player(id: 'a', name: 'Ann'),
          Player(id: 'b', name: 'Bob'),
        ])
        ..submitVisitTotal(60);
      final host = SessionShare(shareTransport()!, session);
      await host.start();
      final guest = await SessionShare.join(shareTransport()!, host.code!);
      expect(guest.controller.events.length, 2);

      session.submitVisitTotal(100);
      await _until(() => guest.controller.events.length == 3);
      guest.controller
        ..throwDart(const Dart.treble(20))
        ..undo()
        ..throwDart(const Dart.single(5));
      await _until(() => session.events.length == 4);
      await _until(() => host.joinedCount == 1);

      host.lockInput(true);
      await _until(() => guest.inputLocked);

      // Ended and left at once: the end still reaches the guest.
      session.endSession();
      host.dispose();
      await _until(() => guest.controller.state.isEnded);
      guest.dispose();

      await expectLater(
        SessionShare.join(
          shareTransport()!,
          '000001',
          timeout: const Duration(seconds: 3),
        ),
        throwsA(isA<NoSuchShare>()),
      );
    },
    skip: _live ? false : 'pass --dart-define=LIVE_SHARE=true to run',
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
