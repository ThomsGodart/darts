import 'package:darts_points_counter/storage/app_database.dart';
import 'package:darts_points_counter/storage/drift_player_catalog.dart';
import 'package:darts_points_counter/storage/drift_soiree_repository.dart';
import 'package:darts_points_counter/soiree/soiree.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../soiree/helpers.dart';

void main() {
  test(
    'a v1 database (before players) upgrades and keeps its soirées',
    () async {
      final database = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            // Schema as shipped with ticket 07.
            raw.execute('''
            CREATE TABLE soirees (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
            );
            CREATE TABLE soiree_events (
              soiree_id INTEGER NOT NULL REFERENCES soirees (id),
              seq INTEGER NOT NULL,
              type TEXT NOT NULL,
              payload TEXT NOT NULL,
              recorded_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
              PRIMARY KEY (soiree_id, seq)
            );
            INSERT INTO soirees (id) VALUES (1);
            INSERT INTO soiree_events (soiree_id, seq, type, payload) VALUES
              (1, 0, 'game_started', '{"players":[{"id":"alice","name":"Alice"},{"id":"bob","name":"Bob"}],"startScore":501,"outRule":"double"}'),
              (1, 1, 'visit_total_submitted', '{"score":60,"darts":3}');
          ''');
            raw.userVersion = 1;
          },
        ),
      );
      addTearDown(database.close);

      final resumed = await DriftSoireeRepository(database).resumable();
      expect(resumed!.state.game!.scoreOf(alice).remaining, 441);

      final catalog = DriftPlayerCatalog(database);
      await catalog.add('Ana');
      expect([for (final p in await catalog.active()) p.name], ['Ana']);
    },
  );
}
