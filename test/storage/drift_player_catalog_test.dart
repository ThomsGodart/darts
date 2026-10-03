import 'package:darts_points_counter/storage/app_database.dart';
import 'package:darts_points_counter/storage/drift_player_catalog.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../session/player_catalog_contract.dart';

void main() {
  playerCatalogContract('drift (in-memory SQLite)', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    return () => DriftPlayerCatalog(database);
  });
}
