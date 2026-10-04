import 'player.dart';
import 'state.dart';

/// What one player did over every session given to [playerStats].
class PlayerStats {
  const PlayerStats({
    required this.player,
    required this.gamesPlayed,
    required this.gamesWon,
    required this.x01Average,
    required this.firstNineAverage,
    required this.tons,
    required this.ton40s,
    required this.ton80s,
    required this.bestCheckout,
    required this.fewestDartsToWin,
    required this.marksPerRound,
    required this.dartsAtDouble,
    required this.checkouts,
  });

  /// The player, under the name of their latest game.
  final Player player;

  /// Finished games of any kind the player took part in, and won.
  final int gamesPlayed;
  final int gamesWon;

  /// Points per three darts over every X01 game, finished or not; null
  /// before the first dart.
  final double? x01Average;

  /// The same over the first three visits of each X01 game only.
  final double? firstNineAverage;

  /// X01 visits of 100 or more, 140 or more, and 180.
  final int tons;
  final int ton40s;
  final int ton80s;

  /// The highest visit the player won an X01 game with.
  final int? bestCheckout;

  /// The fewest darts the player took to win an X01 game, whatever its
  /// start score.
  final int? fewestDartsToWin;

  /// Marks per round over every cricket game; null before the first dart.
  final double? marksPerRound;

  /// Darts thrown at a finish in X01, over the visits that say so (those
  /// entered dart by dart, or as a total with the count given), and the
  /// games won on those visits.
  final int dartsAtDouble;
  final int checkouts;

  /// Checkouts per dart at a finish; null when no visit said.
  double? get checkoutRate =>
      dartsAtDouble == 0 ? null : checkouts / dartsAtDouble;
}

/// Everyone's stats over [sessions], in the order they first played.
/// Matched by id: a player renamed between games stays one player.
List<PlayerStats> playerStats(Iterable<SessionState> sessions) {
  final tallies = <String, _Tally>{};
  for (final session in sessions) {
    for (final game in session.games) {
      for (final player in game.players) {
        // A person's stats: not a team's shared score, not a bot's.
        if (player.isTeam || player.isBot) continue;
        final tally = tallies.putIfAbsent(player.id, _Tally.new)
          ..player = player;
        if (game.isFinished) {
          tally.gamesPlayed++;
          if (game.winner?.id == player.id) tally.gamesWon++;
        }
        switch (game) {
          case X01Game():
            tally.addX01(game, game.scoreOf(player));
          case CricketGame():
            tally.marks += game.scoreOf(player).marksHit;
            tally.rounds += game.roundsOf(player);
          default:
            break;
        }
      }
    }
  }
  return [for (final tally in tallies.values) tally.stats];
}

class _Tally {
  late Player player;
  var gamesPlayed = 0;
  var gamesWon = 0;
  var points = 0;
  var darts = 0;
  var firstNinePoints = 0;
  var firstNineDarts = 0;
  var tons = 0;
  var ton40s = 0;
  var ton80s = 0;
  int? bestCheckout;
  int? fewestDartsToWin;
  var marks = 0;
  var rounds = 0;
  var dartsAtDouble = 0;
  var checkouts = 0;

  void addX01(X01Game game, PlayerScore score) {
    points += score.pointsScored;
    darts += score.dartsThrown;
    for (final visit in score.visits.take(3)) {
      firstNinePoints += visit.points;
      firstNineDarts += visit.darts;
    }
    for (final visit in score.visits) {
      if (visit.points >= 100) tons++;
      if (visit.points >= 140) ton40s++;
      if (visit.points == 180) ton80s++;
    }
    final won = game.winner?.id == score.player.id;
    for (final (i, visit) in score.visits.indexed) {
      final atDouble = visit.dartsAtDouble;
      if (atDouble == null) continue;
      dartsAtDouble += atDouble;
      if (won && i == score.visits.length - 1) checkouts++;
    }
    if (!won) return;
    final checkout = score.lastVisit!.points;
    if (checkout > (bestCheckout ?? 0)) bestCheckout = checkout;
    if (score.dartsThrown < (fewestDartsToWin ?? score.dartsThrown + 1)) {
      fewestDartsToWin = score.dartsThrown;
    }
  }

  PlayerStats get stats => PlayerStats(
    player: player,
    gamesPlayed: gamesPlayed,
    gamesWon: gamesWon,
    x01Average: averagePerVisit(points, darts),
    firstNineAverage: averagePerVisit(firstNinePoints, firstNineDarts),
    tons: tons,
    ton40s: ton40s,
    ton80s: ton80s,
    bestCheckout: bestCheckout,
    fewestDartsToWin: fewestDartsToWin,
    marksPerRound: perRound(marks, rounds),
    dartsAtDouble: dartsAtDouble,
    checkouts: checkouts,
  );
}
