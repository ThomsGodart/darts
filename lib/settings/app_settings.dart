import 'package:flutter/foundation.dart';

/// Where the app's settings are kept between launches.
abstract interface class SettingsStore {
  /// The value stored under [key]; null when it was never set.
  Future<bool?> readBool(String key);

  Future<void> writeBool(String key, {required bool value});
}

/// Settings kept in memory: for tests, and for running without storage.
class InMemorySettingsStore implements SettingsStore {
  final Map<String, bool> _values = {};

  @override
  Future<bool?> readBool(String key) async => _values[key];

  @override
  Future<void> writeBool(String key, {required bool value}) async =>
      _values[key] = value;
}

/// The app's settings, as the screens read and change them.
class AppSettings extends ChangeNotifier {
  AppSettings(this._store);

  /// Keys are stored: never rename one.
  static const _portraitLockKey = 'portraitLock';

  final SettingsStore _store;
  bool _portraitLock = false;

  /// Whether the game screen stays in portrait when the phone is turned.
  /// Off by default: the game screen follows the phone.
  bool get portraitLock => _portraitLock;

  /// Reads the stored settings; until it completes, defaults apply. A
  /// store that cannot be read leaves the defaults in place.
  Future<void> load() async {
    try {
      _portraitLock = await _store.readBool(_portraitLockKey) ?? false;
    } catch (_) {
      return;
    }
    notifyListeners();
  }

  /// Changes the setting at once, then stores it. A store that cannot be
  /// written keeps the choice for this launch only.
  Future<void> setPortraitLock(bool value) async {
    _portraitLock = value;
    notifyListeners();
    try {
      await _store.writeBool(_portraitLockKey, value: value);
    } catch (_) {
      // Nothing to undo: the setting still applies until the app closes.
    }
  }
}
