import 'dart:async';

import 'package:darts_points_counter/soiree/soiree.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Opens a repository on storage that outlives it, so that opening a second
/// one simulates killing and relaunching the app.
typedef OpenRepository = SoireeRepository Function();

/// Behaviour every [SoireeRepository] must have, whatever its storage.
/// [newStorage] sets up empty storage for one test and cleans it up itself.
void repositoryContract(
  String name,
  FutureOr<OpenRepository> Function() newStorage,
) {
  group('$name repository', () {
    late OpenRepository open;

    setUp(() async => open = await newStorage());

    /// Waits for [repository]'s writes, then relaunches on the same storage.
    Future<SoireeRepository> relaunch(SoireeRepository repository) async {
      await repository.flush();
      return open();
    }

    test('nothing to resume on first launch', () async {
      expect(await open().resumable(), isNull);
    });

    test('a game in progress is resumed exactly where it was', () async {
      final repository = open();
      final soiree = await repository.create();
      soiree.startGame([alice, bob]);
      play(soiree, [180, 41, 140]);
      final before = scoreboardOf(soiree);

      final resumed = await (await relaunch(repository)).resumable();

      expect(resumed, isNotNull);
      expect(scoreboardOf(resumed!), before);
      expect(resumed.submitVisitTotal(60), isA<Accepted>());
    });

    test('checkouts, dart counts and undos survive a relaunch', () async {
      final repository = open();
      final soiree = await repository.create();
      soiree.startGame([alice, bob], config: const X01Config(startScore: 301));
      play(soiree, [180, 0]);
      checkOut(soiree, 121);
      soiree.undo();
      play(soiree, [21, 0]);
      checkOut(soiree, 100, darts: 2);
      final before = scoreboardOf(soiree);

      final rebuilt = await (await relaunch(repository)).latest();

      expect(scoreboardOf(rebuilt!), before);
    });

    test('an undo is persisted', () async {
      final repository = open();
      final soiree = await repository.create();
      soiree.startGame([alice, bob]);
      play(soiree, [180, 41]);
      soiree.undo();

      final resumed = await (await relaunch(repository)).resumable();
      expect(resumed!.state.game!.scoreOf(bob).lastVisit, isNull);
      expect(resumed.state.game!.activePlayer, bob);
    });

    test('a resumed soirée keeps recording', () async {
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
      final soiree = await repository.create();
      soiree.startGame([alice, bob]);
      soiree
        ..throwDart(Dart.treble(20))
        ..throwDart(Dart.outerBull)
        ..throwDart(Dart.miss)
        ..throwDart(Dart.bull);
      final before = scoreboardOf(soiree);

      final resumed = await (await relaunch(repository)).resumable();
      expect(scoreboardOf(resumed!), before);
      expect(resumed.state.game!.dartsInVisit, [Dart.bull]);
    });

    test('a soirée whose game is over is offered, to play again', () async {
      final repository = open();
      final soiree = await repository.create();
      soiree.startGame([alice], config: const X01Config(startScore: 40));
      checkOut(soiree, 40, darts: 1);

      final resumed = await (await relaunch(repository)).resumable();
      expect(resumed!.state.game!.winner, alice);
      expect(resumed.rematch(), isA<Accepted>());
    });

    test('an ended soirée is not offered, and stays ended', () async {
      final repository = open();
      final soiree = await repository.create();
      soiree.startGame([alice], config: const X01Config(startScore: 40));
      checkOut(soiree, 40, darts: 1);
      soiree.endSoiree();

      final reopened = await relaunch(repository);
      expect(await reopened.resumable(), isNull);
      expect((await reopened.latest())!.state.isEnded, isTrue);
    });

    test('rematches survive a relaunch', () async {
      final repository = open();
      final soiree = await repository.create();
      soiree.startGame([alice, bob], config: const X01Config(startScore: 40));
      checkOut(soiree, 40, darts: 1);
      soiree.rematch();
      play(soiree, [20]);

      final resumed = await (await relaunch(repository)).resumable();
      expect(resumed!.state.games, hasLength(2));
      expect(scoreboardOf(resumed), scoreboardOf(soiree));
    });

    test('a soirée without a game is not offered for resuming', () async {
      final repository = open();
      await repository.create();
      expect(await (await relaunch(repository)).resumable(), isNull);
    });

    test('only the latest soirée is offered', () async {
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

      test('every soirée with a game, newest first', () async {
        final repository = open();
        final first = await repository.create();
        first
          ..startGame([alice, bob])
          ..endSoiree();
        await repository.create(); // never played: not history
        final second = await repository.create();
        second.startGame([bob]);

        final history = await (await relaunch(repository)).history();

        expect(history, hasLength(2));
        expect(history.first.state.players, [bob]);
        expect(history.first.state.isEnded, isFalse);
        expect(history.last.state.players, [alice, bob]);
        expect(history.last.state.isEnded, isTrue);
        expect(history.first.id, isNot(history.last.id));
        expect(
          history.first.createdAt.isBefore(history.last.createdAt),
          isFalse,
        );
      });

      test('a soirée is replayed in full, games and averages', () async {
        final repository = open();
        final soiree = await repository.create();
        soiree.startGame([alice, bob], config: const X01Config(startScore: 40));
        checkOut(soiree, 40, darts: 1);
        soiree.rematch();
        checkOut(soiree, 40, darts: 2);
        soiree.endSoiree();

        final entry = (await (await relaunch(repository)).history()).single;
        expect([for (final g in entry.state.games) g.winner], [alice, bob]);
        expect(entry.state.averageOf(alice), 120);
      });

      test('a deleted soirée is gone for good', () async {
        final repository = open();
        final kept = await repository.create();
        kept
          ..startGame([alice])
          ..endSoiree();
        final deleted = await repository.create();
        deleted.startGame([bob]);
        play(deleted, [60]);
        final doomed = (await repository.history()).first;

        await repository.delete(doomed.id);

        final reopened = await relaunch(repository);
        final history = await reopened.history();
        expect(history, hasLength(1));
        expect(history.single.state.players, [alice]);
        expect(await reopened.resumable(), isNull);
      });
    });
  });
}
