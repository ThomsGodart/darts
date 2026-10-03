import 'dart:async';

import 'package:darts_points_counter/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Opens a repository on storage that outlives it, so that opening a second
/// one simulates killing and relaunching the app.
typedef OpenRepository = SessionRepository Function();

/// Behaviour every [SessionRepository] must have, whatever its storage.
/// [newStorage] sets up empty storage for one test and cleans it up itself.
void repositoryContract(
  String name,
  FutureOr<OpenRepository> Function() newStorage,
) {
  group('$name repository', () {
    late OpenRepository open;

    setUp(() async => open = await newStorage());

    /// Waits for [repository]'s writes, then relaunches on the same storage.
    Future<SessionRepository> relaunch(SessionRepository repository) async {
      await repository.flush();
      return open();
    }

    test('nothing to resume on first launch', () async {
      expect(await open().resumable(), isNull);
    });

    test('a game in progress is resumed exactly where it was', () async {
      final repository = open();
      final session = await repository.create();
      session.startGame([alice, bob]);
      play(session, [180, 41, 140]);
      final before = scoreboardOf(session);

      final resumed = await (await relaunch(repository)).resumable();

      expect(resumed, isNotNull);
      expect(scoreboardOf(resumed!), before);
      expect(resumed.submitVisitTotal(60), isA<Accepted>());
    });

    test('checkouts, dart counts and undos survive a relaunch', () async {
      final repository = open();
      final session = await repository.create();
      session.startGame([alice, bob], config: const X01Config(startScore: 301));
      play(session, [180, 0]);
      checkOut(session, 121);
      session.undo();
      play(session, [21, 0]);
      checkOut(session, 100, darts: 2);
      final before = scoreboardOf(session);

      final rebuilt = await (await relaunch(repository)).latest();

      expect(scoreboardOf(rebuilt!), before);
    });

    test('an undo is persisted', () async {
      final repository = open();
      final session = await repository.create();
      session.startGame([alice, bob]);
      play(session, [180, 41]);
      session.undo();

      final resumed = await (await relaunch(repository)).resumable();
      expect(resumed!.state.game!.scoreOf(bob).lastVisit, isNull);
      expect(resumed.state.game!.activePlayer, bob);
    });

    test('a resumed session keeps recording', () async {
      final repository = open();
      (await repository.create())
        ..startGame([alice, bob])
        ..submitVisitTotal(60);
      final second = await relaunch(repository);
      (await second.resumable())!.submitVisitTotal(45);

      final third = await (await relaunch(second)).resumable();
      expect(third!.state.game!.scoreOf(bob).remaining, 456);
    });

    test('darts of a visit in progress survive a relaunch', () async {
      final repository = open();
      final session = await repository.create();
      session.startGame([alice, bob]);
      session
        ..throwDart(Dart.treble(20))
        ..throwDart(Dart.outerBull)
        ..throwDart(Dart.miss)
        ..throwDart(Dart.bull);
      final before = scoreboardOf(session);

      final resumed = await (await relaunch(repository)).resumable();
      expect(scoreboardOf(resumed!), before);
      expect(resumed.state.game!.dartsInVisit, [Dart.bull]);
    });

    test('a session whose game is over is offered, to play again', () async {
      final repository = open();
      final session = await repository.create();
      session.startGame([alice], config: const X01Config(startScore: 40));
      checkOut(session, 40, darts: 1);

      final resumed = await (await relaunch(repository)).resumable();
      expect(resumed!.state.game!.winner, alice);
      expect(resumed.rematch(), isA<Accepted>());
    });

    test('an ended session is not offered, and stays ended', () async {
      final repository = open();
      final session = await repository.create();
      session.startGame([alice], config: const X01Config(startScore: 40));
      checkOut(session, 40, darts: 1);
      session.endSession();

      final reopened = await relaunch(repository);
      expect(await reopened.resumable(), isNull);
      expect((await reopened.latest())!.state.isEnded, isTrue);
    });

    test('rematches survive a relaunch', () async {
      final repository = open();
      final session = await repository.create();
      session.startGame([alice, bob], config: const X01Config(startScore: 40));
      checkOut(session, 40, darts: 1);
      session.rematch();
      play(session, [20]);

      final resumed = await (await relaunch(repository)).resumable();
      expect(resumed!.state.games, hasLength(2));
      expect(scoreboardOf(resumed), scoreboardOf(session));
    });

    test('a session without a game is not offered for resuming', () async {
      final repository = open();
      await repository.create();
      expect(await (await relaunch(repository)).resumable(), isNull);
    });

    test('only the latest session is offered', () async {
      final repository = open();
      final first = await repository.create();
      first.startGame([alice, bob]);
      play(first, [60]);
      final second = await repository.create();
      second.startGame([bob, alice]);
      play(second, [100]);

      final resumed = await (await relaunch(repository)).resumable();
      expect(resumed!.state.game!.activePlayer, alice);
      expect(resumed.state.game!.scoreOf(bob).remaining, 401);
    });

    group('history', () {
      test('empty at first', () async {
        expect(await open().history(), isEmpty);
      });

      test('ended sessions only, newest first', () async {
        final repository = open();
        final first = await repository.create();
        first
          ..startGame([alice, bob])
          ..endSession();
        (await repository.create()).endSession(); // never played
        final second = await repository.create();
        second
          ..startGame([bob])
          ..endSession();
        (await repository.create()).startGame([alice]); // still open

        final history = await (await relaunch(repository)).history();

        expect(
          [for (final r in history) r.state.players],
          [
            [bob],
            [alice, bob],
          ],
        );
        expect(history.first.id, isNot(history.last.id));
        expect(
          history.first.createdAt.isBefore(history.last.createdAt),
          isFalse,
        );
      });

      test('several sessions keep their winners and averages', () async {
        final repository = open();
        const forty = X01Config(startScore: 40);
        final first = await repository.create();
        first.startGame([alice, bob], config: forty);
        checkOut(first, 40, darts: 1); // Alice: 40 in 1
        first.rematch();
        play(first, [20]); // Bob: 20 in 3
        checkOut(first, 40, darts: 2); // Alice: 40 in 2
        first.endSession();
        final second = await repository.create();
        second.startGame([bob, alice], config: forty);
        checkOut(second, 40, darts: 3); // Bob: 40 in 3
        second.endSession();

        final history = await (await relaunch(repository)).history();
        final (latest, earliest) = (history.first.state, history.last.state);

        expect([for (final g in earliest.games) g.winner], [alice, alice]);
        expect([for (final g in latest.games) g.winner], [bob]);
        expect(earliest.games[0].scoreOf(alice).threeDartAverage, 120);
        expect(earliest.games[0].scoreOf(bob).threeDartAverage, isNull);
        expect(earliest.games[1].scoreOf(bob).threeDartAverage, 20);
        expect(earliest.games[1].scoreOf(alice).threeDartAverage, 60);
        expect(earliest.averageOf(alice), 80 / 3 * 3);
        expect(earliest.averageOf(bob), 20);
        expect(latest.averageOf(bob), 40);
        expect(latest.averageOf(alice), isNull);
      });

      test('a deleted session is gone for good', () async {
        final repository = open();
        final kept = await repository.create();
        kept
          ..startGame([alice])
          ..endSession();
        final deleted = await repository.create();
        deleted
          ..startGame([bob])
          ..endSession();
        final doomed = (await repository.history()).first;

        await repository.delete(doomed.id);

        final history = await (await relaunch(repository)).history();
        expect(history, hasLength(1));
        expect(history.single.state.players, [alice]);
      });

      test('an unknown id is refused, as is deleting twice', () async {
        final repository = open();
        await expectLater(repository.delete('not-an-id'), throwsArgumentError);
        (await repository.create())
          ..startGame([alice])
          ..endSession();
        final id = (await repository.history()).single.id;
        await repository.delete(id);
        await expectLater(repository.delete(id), throwsArgumentError);
      });
    });
  });
}
