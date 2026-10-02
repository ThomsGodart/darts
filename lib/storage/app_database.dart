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

@DriftDatabase(tables: [Soirees, SoireeEvents])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// The app's database file on the device.
  factory AppDatabase.onDevice() => AppDatabase(driftDatabase(name: 'darts'));

  @override
  int get schemaVersion => 1;
}
