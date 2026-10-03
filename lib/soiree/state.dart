import 'checkout.dart';
import 'dart.dart';
import 'player.dart';
import 'x01_config.dart';
import 'x01_rules.dart';

class SoireeState {
  const SoireeState({this.games = const [], this.isEnded = false});

  /// Every game of the soirée, in the order they were played.
  final List<GameState> games;

  /// Whether the soirée was ended; nothing more can be played then.
  final bool isEnded;

  /// The current (latest) game, or null when none has been started.
  GameState? get game => games.lastOrNull;

  /// Three-dart average of [player] over all their games of the soirée;
  /// null if they have not thrown yet.
  double? averageOf(Player player) {
    var points = 0;
    var darts = 0;
    for (final game in games) {
      for (final score in game.scores) {
        if (score.player != player) continue;
        points += score.pointsScored;
        darts += score.dartsThrown;
      }
    }
    return darts == 0 ? null : points / darts * dartsPerVisit;
  }

  SoireeState withGame(GameState game, {bool isNew = false}) => SoireeState(
    games: List.unmodifiable([
      ...isNew ? games : games.take(games.length - 1),
      game,
    ]),
    isEnded: isEnded,
  );
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
  int get activeRemaining => activeScore.remaining - dartsInVisitScore;

  /// The route to call for the active player to check out with the darts
  /// left in their visit; null when they cannot finish this visit.
  List<Dart>? get checkoutSuggestion =>
      isFinished || activeRemaining > maxCheckoutSuggestion
      ? null
      : suggestCheckout(
          activeRemaining,
          dartsPerVisit - dartsInVisit.length,
          config.outRule,
        );

  /// Points of the darts already thrown in the visit in progress.
  int get dartsInVisitScore => dartsInVisit.fold(0, (sum, d) => sum + d.score);

  /// Throwing order of a rematch: whoever started this game throws last.
  List<Player> get rematchOrder => [
    for (final s in scores.skip(1)) s.player,
    scores.first.player,
  ];

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
