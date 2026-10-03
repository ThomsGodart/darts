import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

@DataClassName('StoredSoiree')
class Soirees extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// The journal of each soirée: one row per event, in order.
@DataClassName('StoredEvent')
class SoireeEvents extends Table {
  IntColumn get soireeId => integer().references(Soirees, #id)();

  /// Position of the event in its soirée's journal, from 0.
  IntColumn get seq => integer()();
  TextColumn get type => text()();

  /// The event's fields as JSON.
  TextColumn get payload => text()();
  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {soireeId, seq};
}

/// The player catalog.
@DataClassName('StoredPlayer')
class Players extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  BoolColumn get hasPlayed => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [Soirees, SoireeEvents, Players])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// The app's database file on the device.
  factory AppDatabase.onDevice() => AppDatabase(driftDatabase(name: 'darts'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(players);
    },
  );
}
