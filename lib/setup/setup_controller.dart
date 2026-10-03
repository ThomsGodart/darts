import 'package:flutter/foundation.dart';

import '../soiree/soiree.dart';

/// What the setup screen hands back: who plays, in order, and the rules.
typedef GameSetup = ({List<Player> players, X01Config config});

/// State of the soirée setup screen, over the player catalog.
class SetupController extends ChangeNotifier {
  /// A blank setup, or one starting from the players and rules of [from].
  SetupController(this._catalog, {GameSetup? from})
    : _picked = [...?from?.players],
      _startScore = from?.config.startScore ?? 501,
      _doubleOut = (from?.config.outRule ?? OutRule.double) == OutRule.double;

  final PlayerCatalog _catalog;

  List<Player> _players = const [];
  bool _disposed = false;
  final List<Player> _picked;
  int _startScore;
  bool _doubleOut;

  /// Players of the catalog, by name.
  List<Player> get players => _players;

  /// Players picked for the game, in throwing order.
  List<Player> get picked => List.unmodifiable(_picked);

  X01Config get config => X01Config(
    startScore: _startScore,
    outRule: _doubleOut ? OutRule.double : OutRule.straight,
  );

  bool get canStart => _picked.isNotEmpty;

  GameSetup get result => (players: picked, config: config);

  Future<void> load() async {
    _players = await _catalog.active();
    // A prefilled setup may carry names changed since: take the catalog's.
    for (final (i, picked) in _picked.indexed) {
      final current = _players.where((p) => p.id == picked.id).firstOrNull;
      if (current != null) _picked[i] = current;
    }
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// The screen may close while the catalog is still answering.
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  bool isPicked(Player player) => _picked.any((p) => p.id == player.id);

  bool canPick(Player player) =>
      isPicked(player) || _picked.length < maxPlayers;

  /// Picks [player] last in the throwing order, or unpicks them.
  void toggle(Player player) {
    if (isPicked(player)) {
      _picked.removeWhere((p) => p.id == player.id);
    } else if (canPick(player)) {
      _picked.add(player);
    } else {
      return;
    }
    notifyListeners();
  }

  /// Moves the picked player at [from] to [to] (indices before the move).
  void reorder(int from, int to) {
    _picked.insert(to, _picked.removeAt(from));
    notifyListeners();
  }

  set startScore(int value) {
    _startScore = value;
    notifyListeners();
  }

  int get startScore => _startScore;

  set doubleOut(bool value) {
    _doubleOut = value;
    notifyListeners();
  }

  bool get doubleOut => _doubleOut;

  /// Adds a player to the catalog and picks them; returns why not, if not.
  Future<PlayerNameProblem?> addPlayer(String name) async {
    final problem = await _catalog.nameProblem(name);
    if (problem != null) return problem;
    final Player player;
    try {
      player = await _catalog.add(name);
    } on ArgumentError {
      // Someone took the name between the check and the add.
      return PlayerNameProblem.taken;
    }
    _players = await _catalog.active();
    if (canPick(player)) _picked.add(player);
    _notify();
    return null;
  }

  Future<PlayerNameProblem?> renamePlayer(Player player, String name) async {
    final problem = await _catalog.nameProblem(name, renaming: player);
    if (problem != null) return problem;
    try {
      await _catalog.rename(player, name);
    } on ArgumentError {
      return PlayerNameProblem.taken;
    }
    _players = await _catalog.active();
    final renamed = _players.where((p) => p.id == player.id).firstOrNull;
    final index = _picked.indexWhere((p) => p.id == player.id);
    if (renamed != null && index != -1) _picked[index] = renamed;
    _notify();
    return null;
  }

  Future<void> removePlayer(Player player) async {
    await _catalog.remove(player);
    _picked.removeWhere((p) => p.id == player.id);
    _players = await _catalog.active();
    _notify();
  }
}
