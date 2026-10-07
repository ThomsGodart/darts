import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

@DataClassName('StoredSession')
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// The journal of each session: one row per event, in order.
@DataClassName('StoredEvent')
class SessionEvents extends Table {
  IntColumn get sessionId => integer().references(Sessions, #id)();

  /// Position of the event in its session's journal, from 0.
  IntColumn get seq => integer()();
  TextColumn get type => text()();

  /// The event's fields as JSON.
  TextColumn get payload => text()();
  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {sessionId, seq};
}

/// The player catalog.
@DataClassName('StoredPlayer')
class Players extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  BoolColumn get hasPlayed => boolean().withDefault(const Constant(false))();
}

/// The app's settings, one row per key.
@DataClassName('StoredSetting')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [Sessions, SessionEvents, Players, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// The app's database file on the device.
  factory AppDatabase.onDevice() => AppDatabase(
    driftDatabase(
      name: 'darts',
      // In a browser, SQLite is a WebAssembly module run by a worker: both
      // files sit in `web/`, at the versions of the sqlite3 and drift
      // packages (see the README).
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    ),
  );

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(players);
      if (from < 3) {
        // The domain was renamed from "soirée" to "session".
        await customStatement('ALTER TABLE soirees RENAME TO sessions');
        await customStatement(
          'ALTER TABLE soiree_events RENAME TO session_events',
        );
        await customStatement(
          'ALTER TABLE session_events RENAME COLUMN soiree_id TO session_id',
        );
        await customStatement(
          "UPDATE session_events SET type = 'session_ended' "
          "WHERE type = 'soiree_ended'",
        );
      }
      if (from < 4) await m.createTable(settings);
    },
  );
}
