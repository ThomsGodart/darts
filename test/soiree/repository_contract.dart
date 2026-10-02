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

    test('a finished game is not offered for resuming', () async {
      final repository = open();
      final soiree = await repository.create();
      soiree.startGame([alice], config: const X01Config(startScore: 40));
      checkOut(soiree, 40, darts: 1);

      expect(await (await relaunch(repository)).resumable(), isNull);
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
  });
}
