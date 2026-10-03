import 'package:darts_points_counter/session/session.dart';

import 'player_catalog_contract.dart';

void main() {
  playerCatalogContract('in-memory', () {
    final storage = InMemoryPlayerStorage();
    return () => InMemoryPlayerCatalog(storage);
  });
}
