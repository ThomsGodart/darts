import 'checkout.dart';
import 'dart.dart';
import 'player.dart';
import 'game_config.dart';
import 'x01_rules.dart';

/// Points per three darts; null before the first dart.
double? averagePerVisit(int points, int darts) =>
    darts == 0 ? null : points / darts * dartsPerVisit;

class SessionState {
  const SessionState({this.games = const [], this.isEnded = false});

  /// Every game of the session, in the order they were played.
  final List<Game> games;

  /// Whether the session was ended; nothing more can be played then.
  final bool isEnded;

  /// The current (latest) game, or null when none has been started.
  Game? get game => games.lastOrNull;

  /// Everyone who played, in the order they first did, under the name they
  /// had in their latest game.
  List<Player> get players {
    // A map keeps each key where it was first inserted; values update.
    final byId = <String, Player>{
      for (final game in games)
        for (final player in game.players) player.id: player,
    };
    return byId.values.toList();
  }

  /// Three-dart average of [player] over their X01 games of the session;
  /// null if they have not thrown in one yet.
  /// Matched by id: a player renamed between games stays one player.
  double? averageOf(Player player) {
    var points = 0;
    var darts = 0;
    for (final game in games.whereType<X01Game>()) {
      for (final score in game.scores) {
        if (score.player.id != player.id) continue;
        points += score.pointsScored;
        darts += score.dartsThrown;
      }
    }
    return averagePerVisit(points, darts);
  }

  SessionState addGame(Game game) => SessionState(
    games: List.unmodifiable([...games, game]),
    isEnded: isEnded,
  );

  SessionState replaceCurrentGame(Game game) => SessionState(
    games: List.unmodifiable([...games.take(games.length - 1), game]),
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
  double? get threeDartAverage => averagePerVisit(pointsScored, dartsThrown);

  PlayerScore after(Visit visit) => PlayerScore(
    player: player,
    remaining: remaining - visit.points,
    lastVisit: visit,
    pointsScored: pointsScored + visit.points,
    dartsThrown: dartsThrown + visit.darts,
    visitsPlayed: visitsPlayed + 1,
  );
}

/// What every game exposes, whatever is played.
sealed class Game {
  const Game();

  GameConfig get config;

  /// Players in throwing order.
  List<Player> get players;
  int get activeIndex;

  /// Darts already thrown in the active player's visit when it is entered
  /// dart by dart; empty between visits.
  List<Dart> get dartsInVisit;
  Player? get winner;

  /// Completed visits, all players together: changes on every turn.
  int get visitsPlayed;

  bool get isFinished => winner != null;

  Player get activePlayer => players[activeIndex];

  /// Throwing order of a rematch: whoever started this game throws last.
  List<Player> get rematchOrder => [...players.skip(1), players.first];
}

/// An X01 game: each player counts down from the start score.
final class X01Game extends Game {
  const X01Game({
    required this.config,
    required this.scores,
    required this.activeIndex,
    this.dartsInVisit = const [],
    this.winner,
  });

  @override
  final X01Config config;

  /// One entry per player, in throwing order.
  final List<PlayerScore> scores;
  @override
  final int activeIndex;
  @override
  final List<Dart> dartsInVisit;
  @override
  final Player? winner;

  @override
  List<Player> get players => [for (final s in scores) s.player];

  PlayerScore get activeScore => scores[activeIndex];

  @override
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

/// One player's side of a cricket board.
class CricketScore {
  const CricketScore({
    required this.player,
    this.marks = const {},
    this.points = 0,
    this.visitsPlayed = 0,
  });

  final Player player;

  /// Marks per cricket number, up to [marksToClose]; absent means none.
  final Map<int, int> marks;
  final int points;
  final int visitsPlayed;

  int marksOn(int number) => marks[number] ?? 0;

  bool isClosed(int number) => marksOn(number) >= marksToClose;

  bool get hasClosedAll => cricketNumbers.every(isClosed);

  CricketScore copyWith({
    Map<int, int>? marks,
    int? points,
    int? visitsPlayed,
  }) => CricketScore(
    player: player,
    marks: marks ?? this.marks,
    points: points ?? this.points,
    visitsPlayed: visitsPlayed ?? this.visitsPlayed,
  );
}

/// A cricket game: close 15–20 and the bull, scoring on what others have
/// left open.
final class CricketGame extends Game {
  const CricketGame({
    required this.config,
    required this.scores,
    required this.activeIndex,
    this.dartsInVisit = const [],
    this.winner,
  });

  @override
  final CricketConfig config;

  /// One entry per player, in throwing order.
  final List<CricketScore> scores;
  @override
  final int activeIndex;
  @override
  final List<Dart> dartsInVisit;
  @override
  final Player? winner;

  @override
  List<Player> get players => [for (final s in scores) s.player];

  CricketScore get activeScore => scores[activeIndex];

  @override
  int get visitsPlayed => scores.fold(0, (sum, s) => sum + s.visitsPlayed);

  CricketScore scoreOf(Player player) =>
      scores.firstWhere((s) => s.player == player);

  /// Closed by every player: no one scores on it any more.
  bool isDead(int number) => scores.every((s) => s.isClosed(number));
}
