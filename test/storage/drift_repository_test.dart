import 'package:darts_points_counter/storage/app_database.dart';
import 'package:darts_points_counter/storage/drift_soiree_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../soiree/repository_contract.dart';

void main() {
  repositoryContract('drift (in-memory SQLite)', () {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    return () => DriftSoireeRepository(database);
  });
}
