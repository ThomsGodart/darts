import 'package:darts_points_counter/storage/app_database.dart';
import 'package:darts_points_counter/storage/drift_player_catalog.dart';
import 'package:darts_points_counter/storage/drift_session_repository.dart';
import 'package:darts_points_counter/storage/drift_settings_store.dart';
import 'package:darts_points_counter/session/session.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../session/helpers.dart';

void main() {
  test(
    'a v1 database (before players) upgrades and keeps its sessions',
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

      final resumed = await DriftSessionRepository(database).resumable();
      expect(resumed!.state.x01!.scoreOf(alice).remaining, 441);

      final catalog = DriftPlayerCatalog(database);
      await catalog.add('Ana');
      expect([for (final p in await catalog.active()) p.name], ['Ana']);
    },
  );

  test(
    'a v2 database (French table names) upgrades to sessions, events kept',
    () async {
      final database = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            // Schema as shipped with ticket 08.
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
            CREATE TABLE players (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              archived INTEGER NOT NULL DEFAULT 0 CHECK (archived IN (0, 1)),
              has_played INTEGER NOT NULL DEFAULT 0 CHECK (has_played IN (0, 1))
            );
            INSERT INTO players (id, name, has_played) VALUES (1, 'Ana', 1);
            INSERT INTO soirees (id) VALUES (1);
            INSERT INTO soiree_events (soiree_id, seq, type, payload) VALUES
              (1, 0, 'game_started', '{"players":[{"id":"1","name":"Ana"}],"startScore":40,"outRule":"double"}'),
              (1, 1, 'visit_total_submitted', '{"score":40,"darts":1}'),
              (1, 2, 'soiree_ended', '{}');
          ''');
            raw.userVersion = 2;
          },
        ),
      );
      addTearDown(database.close);

      final history = await DriftSessionRepository(database).history();
      expect(history.single.state.isEnded, isTrue);
      expect(history.single.state.x01!.winner!.name, 'Ana');

      final players = await DriftPlayerCatalog(database).active();
      expect([for (final p in players) p.name], ['Ana']);
    },
  );

  test('a v3 database (before settings) upgrades and can keep them', () async {
    final database = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          // Schema as shipped in 1.0.0.
          raw.execute('''
            CREATE TABLE sessions (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
            );
            CREATE TABLE session_events (
              session_id INTEGER NOT NULL REFERENCES sessions (id),
              seq INTEGER NOT NULL,
              type TEXT NOT NULL,
              payload TEXT NOT NULL,
              recorded_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
              PRIMARY KEY (session_id, seq)
            );
            CREATE TABLE players (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              archived INTEGER NOT NULL DEFAULT 0 CHECK (archived IN (0, 1)),
              has_played INTEGER NOT NULL DEFAULT 0 CHECK (has_played IN (0, 1))
            );
            INSERT INTO players (id, name, has_played) VALUES (1, 'Ana', 1);
          ''');
          raw.userVersion = 3;
        },
      ),
    );
    addTearDown(database.close);

    final store = DriftSettingsStore(database);
    expect(await store.readBool('portraitLock'), isNull);
    await store.writeBool('portraitLock', value: true);
    expect(await store.readBool('portraitLock'), isTrue);

    final players = await DriftPlayerCatalog(database).active();
    expect([for (final p in players) p.name], ['Ana']);
  });
}
