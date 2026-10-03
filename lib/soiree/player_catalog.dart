import 'player.dart';
import 'player_catalog_rules.dart';

/// Why a name cannot be given to a player.
enum PlayerNameProblem { empty, taken }

/// The players known to the app, kept between soirées.
abstract interface class PlayerCatalog {
  /// Players that can be picked, by name.
  Future<List<Player>> active();

  /// Players removed after they played: kept so past games stay readable.
  Future<List<Player>> archived();

  /// Why [name] cannot be used, or null if it can. A name is taken when an
  /// active player has it, whatever the case; [renaming] may keep its own.
  Future<PlayerNameProblem?> nameProblem(String name, {Player? renaming});

  /// Adds a player; throws [ArgumentError] when [nameProblem] objects.
  Future<Player> add(String name);

  /// Throws [ArgumentError] when [nameProblem] objects.
  Future<void> rename(Player player, String name);

  /// Deletes a player who never played; archives one who did.
  Future<void> remove(Player player);

  /// Records that [players] took part in a game.
  Future<void> markPlayed(Iterable<Player> players);
}

/// Catalog entries kept in memory; outlives the catalogs opened on it.
class InMemoryPlayerStorage {
  final List<CatalogEntry> entries = [];
  int nextId = 1;
}

class InMemoryPlayerCatalog implements PlayerCatalog {
  InMemoryPlayerCatalog([InMemoryPlayerStorage? storage])
    : _storage = storage ?? InMemoryPlayerStorage();

  final InMemoryPlayerStorage _storage;

  List<CatalogEntry> get _entries => _storage.entries;

  CatalogEntry _entryOf(Player player) =>
      _entries.firstWhere((e) => e.player.id == player.id);

  @override
  Future<List<Player>> active() async =>
      playersByName(_entries, archived: false);

  @override
  Future<List<Player>> archived() async =>
      playersByName(_entries, archived: true);

  @override
  Future<PlayerNameProblem?> nameProblem(
    String name, {
    Player? renaming,
  }) async => nameProblemAmong(_entries, name, renaming: renaming);

  @override
  Future<Player> add(String name) async {
    final player = Player(
      id: 'p${_storage.nextId++}',
      name: checkedPlayerName(_entries, name),
    );
    _entries.add(CatalogEntry(player));
    return player;
  }

  @override
  Future<void> rename(Player player, String name) async {
    _entryOf(player).player = Player(
      id: player.id,
      name: checkedPlayerName(_entries, name, renaming: player),
    );
  }

  @override
  Future<void> remove(Player player) async {
    final entry = _entries.where((e) => e.player.id == player.id).firstOrNull;
    if (entry == null) return;
    if (entry.hasPlayed) {
      entry.archived = true;
    } else {
      _entries.remove(entry);
    }
  }

  @override
  Future<void> markPlayed(Iterable<Player> players) async {
    for (final player in players) {
      _entryOf(player).hasPlayed = true;
    }
  }
}
