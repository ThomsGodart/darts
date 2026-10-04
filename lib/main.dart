import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'backend.dart';
import 'crash_reporting.dart';
import 'storage/app_database.dart';
import 'storage/drift_player_catalog.dart';
import 'storage/drift_session_repository.dart';
import 'storage/drift_settings_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Fire-and-forget: optional services must never delay startup.
  unawaited(initCrashReporting());
  unawaited(initBackend());
  final database = AppDatabase.onDevice();
  runApp(
    DartsApp(
      repository: DriftSessionRepository(database),
      catalog: DriftPlayerCatalog(database),
      settingsStore: DriftSettingsStore(database),
    ),
  );
}
