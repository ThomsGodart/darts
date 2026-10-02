import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'backend.dart';
import 'storage/app_database.dart';
import 'storage/drift_soiree_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Fire-and-forget: the backend is optional and must never delay startup.
  unawaited(initBackend());
  runApp(DartsApp(repository: DriftSoireeRepository(AppDatabase.onDevice())));
}
