import 'dart.dart';
import 'player.dart';
import 'x01_config.dart';
import 'x01_rules.dart';

class SoireeState {
  const SoireeState({this.game});

  /// The current game, or null when none has been started.
  final GameState? game;
}

/// One visit as it was played.
class Visit {
  const Visit({required this.score, required this.darts, required this.isBust});

  /// Total entered for the visit, even when it busted.
  final int score;
  final int darts;
  final bool isBust;

  /// Points that count towards the remaining score and the average.
  int get points => isBust ? 0 : score;

  @override
  bool operator ==(Object other) =>
      other is Visit &&
      other.score == score &&
      other.darts == darts &&
      other.isBust == isBust;

  @override
  int get hashCode => Object.hash(score, darts, isBust);
}

class PlayerScore {
  const PlayerScore({
    required this.player,
    required this.remaining,
    this.lastVisit,
    this.pointsScored = 0,
    this.dartsThrown = 0,
    this.visitsPlayed = 0,
  });

  final Player player;
  final int remaining;

  /// The player's latest visit, null before their first.
  final Visit? lastVisit;
  final int pointsScored;
  final int dartsThrown;
  final int visitsPlayed;

  /// Points per three darts, null before the first dart.
  double? get threeDartAverage =>
      dartsThrown == 0 ? null : pointsScored / dartsThrown * dartsPerVisit;

  PlayerScore after(Visit visit) => PlayerScore(
    player: player,
    remaining: remaining - visit.points,
    lastVisit: visit,
    pointsScored: pointsScored + visit.points,
    dartsThrown: dartsThrown + visit.darts,
    visitsPlayed: visitsPlayed + 1,
  );
}

class GameState {
  const GameState({
    required this.config,
    required this.scores,
    required this.activeIndex,
    this.dartsInVisit = const [],
    this.winner,
  });

  final X01Config config;

  /// One entry per player, in throwing order.
  final List<PlayerScore> scores;
  final int activeIndex;

  /// Darts already thrown in the active player's visit when it is entered
  /// dart by dart; empty between visits.
  final List<Dart> dartsInVisit;
  final Player? winner;

  bool get isFinished => winner != null;

  PlayerScore get activeScore => scores[activeIndex];

  Player get activePlayer => activeScore.player;

  /// Completed visits, all players together: changes on every turn.
  int get visitsPlayed => scores.fold(0, (sum, s) => sum + s.visitsPlayed);

  /// The active player's remaining score, counting darts already thrown.
  int get activeRemaining =>
      activeScore.remaining - dartsInVisit.fold(0, (sum, d) => sum + d.score);

  /// Everyone but the active player, in the order they will throw next.
  List<PlayerScore> get waitingInTurnOrder => [
    for (var i = 1; i < scores.length; i++)
      scores[(activeIndex + i) % scores.length],
  ];

  PlayerScore scoreOf(Player player) =>
      scores.firstWhere((s) => s.player == player);

  /// Dart counts the active player may claim if a visit of [score] checks
  /// out; empty when it would not end the game validly.
  List<int> checkoutDartOptions(int score) {
    if (score != activeScore.remaining) return const [];
    final fewest = fewestDartsToFinish(score, config.outRule);
    if (fewest == null) return const [];
    return [for (var darts = fewest; darts <= dartsPerVisit; darts++) darts];
  }
}
