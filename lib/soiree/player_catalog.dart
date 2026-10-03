import 'player.dart';

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

/// One player as a catalog stores it.
class CatalogEntry {
  CatalogEntry(this.player, {this.archived = false, this.hasPlayed = false});

  Player player;
  bool archived;
  bool hasPlayed;
}

/// The catalog's naming rule, over every stored entry.
PlayerNameProblem? nameProblemAmong(
  Iterable<CatalogEntry> entries,
  String name, {
  Player? renaming,
}) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return PlayerNameProblem.empty;
  final taken = entries.any(
    (e) =>
        !e.archived &&
        e.player.id != renaming?.id &&
        e.player.name.toLowerCase() == trimmed.toLowerCase(),
  );
  return taken ? PlayerNameProblem.taken : null;
}

/// The trimmed [name], or an [ArgumentError] saying why it is refused.
String checkedPlayerName(
  Iterable<CatalogEntry> entries,
  String name, {
  Player? renaming,
}) {
  final problem = nameProblemAmong(entries, name, renaming: renaming);
  if (problem != null) throw ArgumentError.value(name, 'name', problem.name);
  return name.trim();
}

/// The players of [entries] that are (or are not) [archived], by name.
List<Player> playersByName(
  Iterable<CatalogEntry> entries, {
  required bool archived,
}) => [
  for (final e in entries)
    if (e.archived == archived) e.player,
]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

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
    final entry = _entryOf(player);
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
