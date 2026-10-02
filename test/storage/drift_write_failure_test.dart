import 'package:darts_points_counter/storage/app_database.dart';
import 'package:darts_points_counter/storage/drift_soiree_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../soiree/helpers.dart';

void main() {
  test(
    'after a failed write, nothing more is stored and flush reports it',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = DriftSoireeRepository(database);
      final soiree = await repository.create();
      soiree.startGame([alice, bob]);
      await repository.flush();

      // Take the slot of the next event so that its insert fails.
      await database
          .into(database.soireeEvents)
          .insert(
            SoireeEventsCompanion.insert(
              soireeId: 1,
              seq: 1,
              type: 'blocker',
              payload: '{}',
            ),
          );
      play(soiree, [60, 45]);

      await expectLater(repository.flush(), throwsA(anything));
      await (database.delete(
        database.soireeEvents,
      )..where((e) => e.type.equals('blocker'))).go();

      // Only a consistent prefix was stored: the game, without the visits
      // after the failure (45 was never written over a gap).
      final reloaded = await DriftSoireeRepository(database).latest();
      expect(reloaded!.state.game!.scoreOf(alice).remaining, 501);
      expect(reloaded.state.game!.scoreOf(bob).remaining, 501);
    },
  );
}
