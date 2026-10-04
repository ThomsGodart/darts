import 'package:flutter/foundation.dart';

import '../session/session.dart';

/// Why a setup cannot start although enough players are picked.
enum SetupProblem {
  /// One of the teams asked for has nobody in it.
  emptyTeam,

  /// A virtual opponent only plays games entered as totals.
  botCannotPlay,
}

/// The games a virtual opponent can play: those entered as a total.
const botGameKinds = {GameKind.x01, GameKind.countUp};

/// State of the session setup screen, over the player catalog.
class SetupController extends ChangeNotifier {
  /// A blank setup, or one starting from the players and rules of [from].
  SetupController(this._catalog, {GameSetup? from})
    : _picked = [
        // Teams open on their members: they are put back together on the
        // way out.
        for (final side in from?.players ?? const <Player>[])
          if (side.isTeam) ...side.members else side,
      ],
      _kind = from?.config.kind ?? GameKind.x01 {
    if (from == null) return;
    _configs[from.config.kind] = from.config;
    if (!from.players.any((side) => side.isTeam)) return;
    _teamCount = from.players.length;
    for (final (team, side) in from.players.indexed) {
      for (final member in side.isTeam ? side.members : [side]) {
        _teamOf[member.id] = team;
      }
    }
  }

  final PlayerCatalog _catalog;

  List<Player> _players = const [];
  bool _disposed = false;
  bool _loading = true;
  String? _loadError;
  final List<Player> _picked;
  GameKind _kind;

  /// Teams asked for; 0 when everyone plays for themselves.
  int _teamCount = 0;

  /// Team of each picked player, by player id, from 0.
  final Map<String, int> _teamOf = {};

  /// The rules last chosen for each game, so switching games and back
  /// loses nothing.
  final Map<GameKind, GameConfig> _configs = {
    for (final kind in GameKind.values) kind: defaultConfigOf(kind),
  };

  /// Players of the catalog, by name.
  List<Player> get players => _players;

  /// True until the first [load] finishes.
  bool get loading => _loading;

  /// Set when [load] fails; cleared on the next successful load.
  String? get loadError => _loadError;

  /// Players picked for the game, in throwing order.
  List<Player> get picked => List.unmodifiable(_picked);

  /// The game picked.
  GameKind get kind => _kind;

  set kind(GameKind value) {
    _kind = value;
    notifyListeners();
  }

  /// The rules of the game picked. Setting rules picks their game.
  GameConfig get config => _configs[_kind]!;

  set config(GameConfig value) {
    _configs[value.kind] = value;
    _kind = value.kind;
    notifyListeners();
  }

  /// Teams asked for; 0 when everyone plays for themselves.
  int get teamCount => _teamCount;

  /// Asks for [value] teams and deals the picked players out in turn;
  /// they then choose who is with whom through [assign].
  set teamCount(int value) {
    _teamCount = value;
    _teamOf.clear();
    for (final (i, player) in _picked.indexed) {
      if (value > 0) _teamOf[player.id] = i % value;
    }
    notifyListeners();
  }

  /// The team [player] is in, from 0.
  int teamOf(Player player) => _teamOf[player.id] ?? 0;

  /// Puts [player] in [team].
  void assign(Player player, int team) {
    _teamOf[player.id] = team;
    notifyListeners();
  }

  /// Members of each team asked for, in throwing order.
  List<List<Player>> get _teams => [
    for (var team = 0; team < _teamCount; team++)
      [
        for (final player in _picked)
          if (teamOf(player) == team) player,
      ],
  ];

  /// Who holds a score in the game: the picked players, or their teams.
  /// Someone alone in a team is just themselves.
  List<Player> get sides => _teamCount == 0
      ? picked
      : [
          for (final members in _teams)
            if (members.length == 1)
              members.single
            else if (members.isNotEmpty)
              Player.team(members),
        ];

  /// What keeps the game from starting besides a lack of players; null
  /// when nothing does.
  SetupProblem? get problem {
    final teams = _teams;
    if (teams.any((members) => members.isEmpty)) return SetupProblem.emptyTeam;
    if (_picked.any((p) => p.isBot) && !botGameKinds.contains(_kind)) {
      return SetupProblem.botCannotPlay;
    }
    return null;
  }

  bool get canStart => problem == null && sides.length >= config.minPlayers;

  GameSetup get result => (players: sides, config: config);

  Future<void> load() async {
    _loading = true;
    _loadError = null;
    _notify();
    try {
      _players = await _catalog.active();
      // A prefilled setup may carry names changed since, or players
      // removed since: take the catalog's word for both.
      final current = {for (final player in _players) player.id: player};
      final stillThere = [
        for (final picked in _picked)
          // A virtual opponent is in no catalog.
          if (picked.isBot) picked else ?current[picked.id],
      ];
      _picked
        ..clear()
        ..addAll(stillThere);
    } catch (_) {
      _loadError = 'Impossible de charger les joueurs.';
    }
    _loading = false;
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
      _teamOf.remove(player.id);
    } else if (canPick(player)) {
      _pick(player);
    } else {
      return;
    }
    notifyListeners();
  }

  /// Picks [player] last; with teams, into the one with the fewest
  /// players.
  void _pick(Player player) {
    if (_teamCount > 0) {
      final teams = _teams;
      var smallest = 0;
      for (var team = 1; team < teams.length; team++) {
        if (teams[team].length < teams[smallest].length) smallest = team;
      }
      _teamOf[player.id] = smallest;
    }
    _picked.add(player);
  }

  /// Moves the picked player at [from] to [to] (indices before the move).
  void reorder(int from, int to) {
    _picked.insert(to, _picked.removeAt(from));
    notifyListeners();
  }

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
    if (canPick(player)) _pick(player);
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
