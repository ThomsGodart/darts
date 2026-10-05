import '../settings/app_settings.dart';
import 'app_database.dart';

/// The app's settings in the device database, one row per key.
class DriftSettingsStore implements SettingsStore {
  DriftSettingsStore(this._db);

  final AppDatabase _db;

  @override
  Future<bool?> readBool(String key) async {
    final stored = await readString(key);
    return stored == null ? null : stored == 'true';
  }

  @override
  Future<void> writeBool(String key, {required bool value}) =>
      writeString(key, '$value');

  @override
  Future<String?> readString(String key) async {
    final row = await (_db.select(
      _db.settings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  @override
  Future<void> writeString(String key, String value) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));
}
