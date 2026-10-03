import 'package:drift/drift.dart';

import '../soiree/soiree.dart';
import 'app_database.dart';

/// Keeps the player catalog in the app's SQLite database.
class DriftPlayerCatalog implements PlayerCatalog {
  DriftPlayerCatalog(this._db);

  final AppDatabase _db;

  Future<List<CatalogEntry>> _entries() async => [
    for (final row in await _db.select(_db.players).get())
      CatalogEntry(
        Player(id: '${row.id}', name: row.name),
        archived: row.archived,
        hasPlayed: row.hasPlayed,
      ),
  ];

  /// Rows of [player], by its database id.
  UpdateStatement<$PlayersTable, StoredPlayer> _update(Player player) =>
      _db.update(_db.players)..where((p) => p.id.equals(int.parse(player.id)));

  @override
  Future<List<Player>> active() async =>
      playersByName(await _entries(), archived: false);

  @override
  Future<List<Player>> archived() async =>
      playersByName(await _entries(), archived: true);

  @override
  Future<PlayerNameProblem?> nameProblem(
    String name, {
    Player? renaming,
  }) async => nameProblemAmong(await _entries(), name, renaming: renaming);

  @override
  Future<Player> add(String name) async {
    final checked = checkedPlayerName(await _entries(), name);
    final id = await _db
        .into(_db.players)
        .insert(PlayersCompanion.insert(name: checked));
    return Player(id: '$id', name: checked);
  }

  @override
  Future<void> rename(Player player, String name) async {
    final checked = checkedPlayerName(await _entries(), name, renaming: player);
    await _update(player).write(PlayersCompanion(name: Value(checked)));
  }

  @override
  Future<void> remove(Player player) async {
    final id = int.parse(player.id);
    await _db.transaction(() async {
      final row = await (_db.select(
        _db.players,
      )..where((p) => p.id.equals(id))).getSingle();
      if (row.hasPlayed) {
        await _update(player)
            .write(const PlayersCompanion(archived: Value(true)));
      } else {
        await (_db.delete(_db.players)..where((p) => p.id.equals(id))).go();
      }
    });
  }

  @override
  Future<void> markPlayed(Iterable<Player> players) async {
    final ids = [for (final p in players) int.parse(p.id)];
    await (_db.update(_db.players)..where((p) => p.id.isIn(ids))).write(
      const PlayersCompanion(hasPlayed: Value(true)),
    );
  }
}
