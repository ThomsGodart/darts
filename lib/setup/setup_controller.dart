import 'package:flutter/foundation.dart';

import '../session/session.dart';

/// What the setup screen hands back: who plays, in order, and the rules.
typedef GameSetup = ({List<Player> players, GameConfig config});

/// The games the setup offers.
enum GameKind { x01, cricket, shanghai, killer }

/// State of the session setup screen, over the player catalog.
class SetupController extends ChangeNotifier {
  /// A blank setup, or one starting from the players and rules of [from].
  SetupController(this._catalog, {GameSetup? from})
    : _picked = [...?from?.players],
      _kind = switch (from?.config) {
        CricketConfig() => GameKind.cricket,
        ShanghaiConfig() => GameKind.shanghai,
        KillerConfig() => GameKind.killer,
        _ => GameKind.x01,
      },
      _variant = switch (from?.config) {
        CricketConfig(:final variant) => variant,
        _ => CricketVariant.standard,
      },
      _cricketInput = switch (from?.config) {
        CricketConfig(:final input) => input,
        _ => CricketInput.board,
      },
      _shanghaiLength = switch (from?.config) {
        ShanghaiConfig(:final length) => length,
        _ => ShanghaiLength.oneToSeven,
      },
      _instantShanghai = switch (from?.config) {
        ShanghaiConfig(:final instantShanghai) => instantShanghai,
        _ => true,
      },
      _killerLives = switch (from?.config) {
        KillerConfig(:final lives) => lives,
        _ => 3,
      },
      _doublesToKiller = switch (from?.config) {
        KillerConfig(:final doublesToKiller) => doublesToKiller,
        _ => 1,
      },
      _startScore = _x01Of(from)?.startScore ?? 501,
      _doubleOut = (_x01Of(from)?.outRule ?? OutRule.double) == OutRule.double;

  static X01Config? _x01Of(GameSetup? setup) => switch (setup?.config) {
    final X01Config config => config,
    _ => null,
  };

  final PlayerCatalog _catalog;

  List<Player> _players = const [];
  bool _disposed = false;
  bool _loading = true;
  String? _loadError;
  final List<Player> _picked;
  GameKind _kind;
  CricketVariant _variant;
  CricketInput _cricketInput;
  ShanghaiLength _shanghaiLength;
  bool _instantShanghai;
  int _killerLives;
  int _doublesToKiller;
  int _startScore;
  bool _doubleOut;

  /// Players of the catalog, by name.
  List<Player> get players => _players;

  /// True until the first [load] finishes.
  bool get loading => _loading;

  /// Set when [load] fails; cleared on the next successful load.
  String? get loadError => _loadError;

  /// Players picked for the game, in throwing order.
  List<Player> get picked => List.unmodifiable(_picked);

  GameConfig get config => switch (_kind) {
    GameKind.x01 => X01Config(
      startScore: _startScore,
      outRule: _doubleOut ? OutRule.double : OutRule.straight,
    ),
    GameKind.cricket => CricketConfig(variant: _variant, input: _cricketInput),
    GameKind.shanghai => ShanghaiConfig(
      length: _shanghaiLength,
      instantShanghai: _instantShanghai,
    ),
    GameKind.killer => KillerConfig(
      lives: _killerLives,
      doublesToKiller: _doublesToKiller,
    ),
  };

  GameKind get kind => _kind;

  CricketVariant get variant => _variant;

  set variant(CricketVariant value) {
    _variant = value;
    notifyListeners();
  }

  CricketInput get cricketInput => _cricketInput;

  set cricketInput(CricketInput value) {
    _cricketInput = value;
    notifyListeners();
  }

  ShanghaiLength get shanghaiLength => _shanghaiLength;

  set shanghaiLength(ShanghaiLength value) {
    _shanghaiLength = value;
    notifyListeners();
  }

  bool get instantShanghai => _instantShanghai;

  set instantShanghai(bool value) {
    _instantShanghai = value;
    notifyListeners();
  }

  int get killerLives => _killerLives;

  set killerLives(int value) {
    _killerLives = value;
    notifyListeners();
  }

  int get doublesToKiller => _doublesToKiller;

  set doublesToKiller(int value) {
    _doublesToKiller = value;
    notifyListeners();
  }

  set kind(GameKind value) {
    _kind = value;
    notifyListeners();
  }

  bool get canStart => switch (_kind) {
    GameKind.killer => _picked.length >= minKillerPlayers,
    _ => _picked.isNotEmpty,
  };

  GameSetup get result => (players: picked, config: config);

  Future<void> load() async {
    _loading = true;
    _loadError = null;
    _notify();
    try {
      _players = await _catalog.active();
      // A prefilled setup may carry names changed since: take the catalog's.
      for (final (i, picked) in _picked.indexed) {
        final current = _players.where((p) => p.id == picked.id).firstOrNull;
        if (current != null) _picked[i] = current;
      }
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
