import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Where the app's settings are kept between launches.
abstract interface class SettingsStore {
  /// The value stored under [key]; null when it was never set.
  Future<bool?> readBool(String key);

  Future<void> writeBool(String key, {required bool value});

  /// The text stored under [key]; null when it was never set.
  Future<String?> readString(String key);

  Future<void> writeString(String key, String value);
}

/// Settings kept in memory: for tests, and for running without storage.
class InMemorySettingsStore implements SettingsStore {
  final Map<String, Object> _values = {};

  @override
  Future<bool?> readBool(String key) async => _values[key] as bool?;

  @override
  Future<void> writeBool(String key, {required bool value}) async =>
      _values[key] = value;

  @override
  Future<String?> readString(String key) async => _values[key] as String?;

  @override
  Future<void> writeString(String key, String value) async =>
      _values[key] = value;
}

/// The app's settings, as the screens read and change them.
class AppSettings extends ChangeNotifier {
  AppSettings(this._store);

  /// Keys are stored: never rename one.
  static const _portraitLockKey = 'portraitLock';
  static const _statsHiddenPlayersKey = 'statsHiddenPlayers';

  final SettingsStore _store;
  bool _portraitLock = false;

  /// Whether the game screen stays in portrait when the phone is turned.
  /// Off by default: the game screen follows the phone.
  bool get portraitLock => _portraitLock;

  Set<String> _statsHiddenPlayers = const {};

  /// Ids of the players left out of the stats screen. Kept as who is
  /// hidden rather than who is shown, so that a new player shows up.
  Set<String> get statsHiddenPlayers => _statsHiddenPlayers;

  /// Reads the stored settings; until it completes, defaults apply. A
  /// store that cannot be read leaves the defaults in place.
  Future<void> load() async {
    try {
      _portraitLock = await _store.readBool(_portraitLockKey) ?? false;
      final hidden = await _store.readString(_statsHiddenPlayersKey);
      if (hidden != null) {
        _statsHiddenPlayers = {...(jsonDecode(hidden) as List).cast<String>()};
      }
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

  /// Changes who the stats leave out at once, then stores it.
  Future<void> setStatsHiddenPlayers(Set<String> ids) async {
    _statsHiddenPlayers = Set.unmodifiable(ids);
    notifyListeners();
    try {
      await _store.writeString(
        _statsHiddenPlayersKey,
        jsonEncode(ids.toList()..sort()),
      );
    } catch (_) {
      // Nothing to undo: the choice still applies until the app closes.
    }
  }
}
