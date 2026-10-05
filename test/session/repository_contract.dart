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

    test('a cancelled game is gone after a relaunch', () async {
      final repository = open();
      final session = await repository.create();
      session.startGame([alice, bob], config: const X01Config(startScore: 40));
      session.submitVisitTotal(40, dartsAtCheckout: 1);
      session.rematch();
      session
        ..submitVisitTotal(20)
        ..throwDart(const Dart.single(5))
        ..cancelGame();

      final rebuilt = (await (await relaunch(repository)).latest())!;
      expect(rebuilt.state.games, hasLength(1));
      expect(rebuilt.state.game!.winner, alice);
    });

    test('an undo is persisted', () async {
      final repository = open();
      final session = await repository.create();
      session.startGame([alice, bob]);
      play(session, [180, 41]);
      session.undo();

      final resumed = await (await relaunch(repository)).resumable();
      expect(resumed!.state.x01!.scoreOf(bob).lastVisit, isNull);
      expect(resumed.state.x01!.activePlayer, bob);
    });

    test('a resumed session keeps recording', () async {
      final repository = open();
      (await repository.create())
        ..startGame([alice, bob])
        ..submitVisitTotal(60);
      final second = await relaunch(repository);
      (await second.resumable())!.submitVisitTotal(45);

      final third = await (await relaunch(second)).resumable();
      expect(third!.state.x01!.scoreOf(bob).remaining, 456);
    });

    test('darts of a visit in progress survive a relaunch', () async {
      final repository = open();
      final session = await repository.create();
      session.startGame([alice, bob]);
      session
        ..throwDart(Dart.treble(20))
        ..throwDart(Dart.outerBull)
        ..throwDart(Dart.miss)
        ..endVisit()
        ..throwDart(Dart.bull);
      final before = scoreboardOf(session);

      final resumed = await (await relaunch(repository)).resumable();
      expect(scoreboardOf(resumed!), before);
      expect(resumed.state.x01!.dartsInVisit, [Dart.bull]);
    });

    test('a session whose game is over is offered, to play again', () async {
      final repository = open();
      final session = await repository.create();
      session.startGame([alice], config: const X01Config(startScore: 40));
      checkOut(session, 40, darts: 1);

      final resumed = await (await relaunch(repository)).resumable();
      expect(resumed!.state.x01!.winner, alice);
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

    test('a mixed X01 and cricket session survives a relaunch', () async {
      final repository = open();
      final session = await repository.create();
      session.startGame([alice, bob], config: const X01Config(startScore: 40));
      checkOut(session, 40, darts: 1);
      session
        ..startGame([bob, alice], config: const CricketConfig())
        ..throwDart(const Dart.treble(20))
        ..throwDart(const Dart.single(20))
        ..throwDart(Dart.bull)
        ..endVisit();
      session.throwDart(const Dart.double(19));
      final before = scoreboardOf(session);

      final resumed = await (await relaunch(repository)).resumable();

      expect(resumed!.state.games.first, isA<X01Game>());
      expect(resumed.state.game, isA<CricketGame>());
      expect(scoreboardOf(resumed), before);
      expect(resumed.state.game!.dartsInVisit, [const Dart.double(19)]);
    });

    test('a Shanghai game in progress survives a relaunch', () async {
      final repository = open();
      final session = await repository.create();
      session
        ..startGame([alice, bob], config: const ShanghaiConfig())
        ..throwDart(const Dart.treble(1))
        ..throwDart(const Dart.single(1));
      final before = scoreboardOf(session);

      final resumed = await (await relaunch(repository)).resumable();

      expect(resumed!.state.game, isA<ShanghaiGame>());
      expect(scoreboardOf(resumed), before);
    });

    test('a Killer game mid-assignment survives a relaunch', () async {
      const carol = Player(id: 'carol', name: 'Carol');
      final repository = open();
      final session = await repository.create();
      session
        ..startGame([alice, bob, carol], config: const KillerConfig())
        ..assignNumber(20)
        ..assignNumber(19);
      final before = scoreboardOf(session);

      final resumed = await (await relaunch(repository)).resumable();

      expect(resumed!.state.game, isA<KillerGame>());
      expect(scoreboardOf(resumed), before);
      expect(resumed.assignNumber(18), isA<Accepted>());
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
      expect(resumed!.state.x01!.activePlayer, alice);
      expect(resumed.state.x01!.scoreOf(bob).remaining, 401);
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
        final firstGames = earliest.games.cast<X01Game>();

        expect([for (final g in earliest.games) g.winner], [alice, alice]);
        expect([for (final g in latest.games) g.winner], [bob]);
        expect(firstGames[0].scoreOf(alice).threeDartAverage, 120);
        expect(firstGames[0].scoreOf(bob).threeDartAverage, isNull);
        expect(firstGames[1].scoreOf(bob).threeDartAverage, 20);
        expect(firstGames[1].scoreOf(alice).threeDartAverage, 60);
        expect(earliest.averageOf(alice), 80 / 3 * 3);
        expect(earliest.averageOf(bob), 20);
        expect(latest.averageOf(bob), 40);
        expect(latest.averageOf(alice), isNull);
      });

      test('a mixed session keeps its winners, MPR and averages', () async {
        final repository = open();
        final session = await repository.create();
        session.startGame([
          alice,
          bob,
        ], config: const X01Config(startScore: 40));
        checkOut(session, 40, darts: 1);
        session.startGame([bob, alice], config: const CricketConfig());
        for (final dart in [
          const Dart.treble(20),
          const Dart.treble(19),
          const Dart.treble(18),
          Dart.miss,
          Dart.miss,
          Dart.miss,
          const Dart.treble(17),
          const Dart.treble(16),
          const Dart.treble(15),
          Dart.miss,
          Dart.miss,
          Dart.miss,
          Dart.bull,
          Dart.outerBull,
        ]) {
          session.throwDart(dart);
          if (session.state.game!.visitIsOver) session.endVisit();
        }
        session.endSession();

        final state = (await (await relaunch(
          repository,
        )).history()).single.state;
        expect([for (final g in state.games) g.winner], [alice, bob]);
        expect(state.averageOf(alice), 120);
        expect(state.averageOf(bob), isNull);
        expect(state.marksPerRoundOf(bob), 21 / 3);
        expect(state.marksPerRoundOf(alice), 0);
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

      test('every played session is listed with when its games started, '
          'the open one too', () async {
        final repository = open();
        (await repository.create())
          ..startGame([alice], config: const X01Config(startScore: 40))
          ..submitVisitTotal(40, dartsAtCheckout: 1)
          ..rematch()
          ..endSession();
        (await repository.create()).startGame([bob]);
        // Never played in: not a session to list.
        final before = DateTime.now().subtract(const Duration(minutes: 1));

        final played = await (await relaunch(repository)).played();
        expect([for (final r in played) r.state.isEnded], [false, true]);
        expect(played.first.gameStartedAt, hasLength(1));
        expect(played.last.gameStartedAt, hasLength(2));
        for (final at in played.last.gameStartedAt) {
          expect(at.isAfter(before), isTrue);
        }
      });

      test('deleting the history leaves the open session alone', () async {
        final repository = open();
        for (final player in [alice, bob]) {
          (await repository.create())
            ..startGame([player])
            ..endSession();
        }
        (await repository.create())
          ..startGame([alice, bob])
          ..submitVisitTotal(60);

        await repository.deleteHistory();

        final relaunched = await relaunch(repository);
        expect(await relaunched.history(), isEmpty);
        final open_ = await relaunched.resumable();
        expect(open_!.state.x01!.scoreOf(alice).remaining, 441);
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
