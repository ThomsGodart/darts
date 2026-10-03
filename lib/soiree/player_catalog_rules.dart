import 'player.dart';
import 'player_catalog.dart';

// Rules shared by the [PlayerCatalog] implementations. Not exported by the
// soirée library: only catalogs use them.

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
