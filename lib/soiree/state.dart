import 'player.dart';
import 'x01_config.dart';

class SoireeState {
  const SoireeState({this.game});

  /// The current game, or null when none has been started.
  final GameState? game;
}

class PlayerScore {
  const PlayerScore({
    required this.player,
    required this.remaining,
    this.lastVisit,
  });

  final Player player;
  final int remaining;

  /// Points scored on the player's latest visit, null before their first.
  final int? lastVisit;
}

class GameState {
  const GameState({
    required this.config,
    required this.scores,
    required this.activeIndex,
    this.winner,
  });

  final X01Config config;

  /// One entry per player, in throwing order.
  final List<PlayerScore> scores;
  final int activeIndex;
  final Player? winner;

  bool get isFinished => winner != null;

  PlayerScore get activeScore => scores[activeIndex];

  Player get activePlayer => activeScore.player;

  /// Everyone but the active player, in the order they will throw next.
  List<PlayerScore> get waitingInTurnOrder => [
    for (var i = 1; i < scores.length; i++)
      scores[(activeIndex + i) % scores.length],
  ];

  PlayerScore scoreOf(Player player) =>
      scores.firstWhere((s) => s.player == player);
}
