import '../settings/app_settings.dart';
import 'app_database.dart';

/// The app's settings in the device database, one row per key.
class DriftSettingsStore implements SettingsStore {
  DriftSettingsStore(this._db);

  final AppDatabase _db;

  @override
  Future<bool?> readBool(String key) async {
    final row = await (_db.select(
      _db.settings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    return row == null ? null : row.value == 'true';
  }

  @override
  Future<void> writeBool(String key, {required bool value}) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(
        SettingsCompanion.insert(key: key, value: '$value'),
      );
}
