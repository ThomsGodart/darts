import 'package:darts_points_counter/settings/app_settings.dart';
import 'package:darts_points_counter/storage/app_database.dart';
import 'package:darts_points_counter/storage/drift_settings_store.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _BrokenStore implements SettingsStore {
  @override
  Future<bool?> readBool(String key) => throw StateError('no disk');

  @override
  Future<void> writeBool(String key, {required bool value}) =>
      throw StateError('no disk');
}

void main() {
  test('the game screen follows the phone until asked otherwise', () async {
    final settings = AppSettings(InMemorySettingsStore());
    await settings.load();
    expect(settings.portraitLock, isFalse);
  });

  test('a change applies at once, tells who listens, and is kept', () async {
    final store = InMemorySettingsStore();
    final settings = AppSettings(store);
    var notified = 0;
    settings.addListener(() => notified++);

    await settings.setPortraitLock(true);
    expect(settings.portraitLock, isTrue);
    expect(notified, 1);

    final relaunched = AppSettings(store);
    await relaunched.load();
    expect(relaunched.portraitLock, isTrue);
  });

  test('a store that cannot be used leaves the app working', () async {
    final settings = AppSettings(_BrokenStore());
    await settings.load();
    expect(settings.portraitLock, isFalse);

    await settings.setPortraitLock(true);
    expect(settings.portraitLock, isTrue);
  });

  test('the device database keeps settings across launches', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final store = DriftSettingsStore(database);

    expect(await store.readBool('portraitLock'), isNull);
    await store.writeBool('portraitLock', value: true);
    expect(await store.readBool('portraitLock'), isTrue);
    await store.writeBool('portraitLock', value: false);
    expect(await store.readBool('portraitLock'), isFalse);
  });
}
