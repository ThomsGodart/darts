import 'package:darts_points_counter/storage/app_database.dart';
import 'package:darts_points_counter/storage/drift_session_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../session/repository_contract.dart';

void main() {
  repositoryContract('drift (in-memory SQLite)', () {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    return () => DriftSessionRepository(database);
  });
}
