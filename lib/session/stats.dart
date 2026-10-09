import 'dart.dart';
import 'game_config.dart';
import 'match.dart';
import 'player.dart';
import 'repository.dart';
import 'state.dart';

/// A game as the stats see it: what was played, and when it started.
class PlayedGame {
  const PlayedGame({
    required this.game,
    required this.startedAt,
    this.matchWinner,
  });

  final Game game;
  final DateTime startedAt;

  /// Who won the match this game was the deciding leg of; null for any
  /// other game.
  final Player? matchWinner;
}

/// The games of [records], oldest session first, each with its date and
/// the match it decided.
List<PlayedGame> playedGames(Iterable<SessionRecord> records) => [
  for (final record in records.toList().reversed)
    for (final (i, game) in record.state.games.indexed)
      PlayedGame(
        game: game,
        startedAt: record.gameStartedAt.elementAtOrNull(i) ?? record.createdAt,
        matchWinner: game.isFinished
            ? matchOf(record.state.games.sublist(0, i + 1))?.winner
            : null,
      ),
];

/// How someone took part in a game.
enum Participation {
  any,

  /// Holding their own score.
  solo,

  /// As a member of a team.
  team,
}

/// Which games, and whose part in them, the stats are counted over.
class StatsQuery {
  const StatsQuery({
    required this.kind,
    this.since,
    this.participation = Participation.any,
    this.startScore,
    this.variant,
  });

  final GameKind kind;

  /// Only the games started from then on; null for all of them.
  final DateTime? since;
  final Participation participation;

  /// Only the X01 games counted down from there; null for any.
  final int? startScore;

  /// Only the cricket games of that variant; null for any.
  final CricketVariant? variant;

  bool _takes(PlayedGame played) {
    final config = played.game.config;
    if (config.kind != kind) return false;
    if (since case final since? when played.startedAt.isBefore(since)) {
      return false;
    }
    if (startScore != null &&
        config is X01Config &&
        config.startScore != startScore) {
      return false;
    }
    if (variant != null &&
        config is CricketConfig &&
        config.variant != variant) {
      return false;
    }
    return true;
  }
}

/// One person's stats over the games of one kind. Throwing stats count
/// every dart thrown, in games left unfinished too; games, wins and
/// records count finished games only.
sealed class GameStats {
  const GameStats({
    required this.player,
    required this.gamesPlayed,
    required this.gamesWon,
  });

  /// The person, under the name of their latest game.
  final Player player;

  /// Finished games they took part in, and won — a team's win being a
  /// win for each of its members.
  final int gamesPlayed;
  final int gamesWon;

  /// Null before the first finished game.
  double? get winRate => gamesPlayed == 0 ? null : gamesWon / gamesPlayed;
}

final class X01Stats extends GameStats {
  const X01Stats({
    required super.player,
    required super.gamesPlayed,
    required super.gamesWon,
    required this.average,
    required this.firstNineAverage,
    required this.bestVisit,
    required this.sixtyPlus,
    required this.tons,
    required this.ton40s,
    required this.ton80s,
    required this.dartsAtDouble,
    required this.checkouts,
    required this.bestCheckout,
    required this.fewestDartsToWin,
    required this.dartsPerLegWon,
    required this.dartsThrown,
    required this.matchesPlayed,
    required this.matchesWon,
  });

  /// Points per three darts; null before the first dart.
  final double? average;

  /// The same over their first three visits of each game.
  final double? firstNineAverage;

  /// Their highest visit; null before the first.
  final int? bestVisit;

  /// Visits of 60 or more, 100 or more, 140 or more, and 180.
  final int sixtyPlus;
  final int tons;
  final int ton40s;
  final int ton80s;

  /// Darts thrown at a finish, over the visits that say so, and the
  /// games won on those visits.
  final int dartsAtDouble;
  final int checkouts;

  /// Checkouts per dart at a finish; null when no visit said.
  double? get checkoutRate =>
      dartsAtDouble == 0 ? null : checkouts / dartsAtDouble;

  /// The highest visit they won a game with.
  final int? bestCheckout;

  /// The fewest darts they took to win a game on their own, and their
  /// mean over the games won that way.
  final int? fewestDartsToWin;
  final double? dartsPerLegWon;

  final int dartsThrown;

  /// Matches of several legs that were decided, and those they won.
  final int matchesPlayed;
  final int matchesWon;
}

final class CricketStats extends GameStats {
  const CricketStats({
    required super.player,
    required super.gamesPlayed,
    required super.gamesWon,
    required this.marksPerRound,
    required this.bestRound,
    required this.fiveMarkRounds,
    required this.sevenMarkRounds,
    required this.nineMarkRounds,
    required this.roundsPerGame,
    required this.fewestRoundsToWin,
    required this.pointsPerGame,
    required this.bulls,
    required this.roundsPlayed,
  });

  /// Marks per round; null before the first round.
  final double? marksPerRound;

  /// The most marks in one round; null before the first.
  final int? bestRound;

  /// Rounds of 5 marks or more, 7 or more, and 9.
  final int fiveMarkRounds;
  final int sevenMarkRounds;
  final int nineMarkRounds;

  /// Their side's rounds and points per finished game.
  final double? roundsPerGame;
  final double? pointsPerGame;

  /// The fewest rounds their side took to win a game.
  final int? fewestRoundsToWin;

  /// Darts in the bull, outer or inner.
  final int bulls;

  final int roundsPlayed;
}

/// The stats of a game that ends on a score: Shanghai, Halve-It, Golf,
/// Bob's 27, Count-Up, Baseball. Killer and Around the Clock, which do
/// not, only have their games and wins.
final class ScoreStats extends GameStats {
  const ScoreStats({
    required super.player,
    required super.gamesPlayed,
    required super.gamesWon,
    required this.averageScore,
    required this.bestScore,
  });

  /// Their side's final score over finished games; null when the game
  /// has none.
  final double? averageScore;

  /// The highest — in Golf, the fewest strokes.
  final int? bestScore;
}

/// The stats of everyone who took part in the games [query] takes, in
/// the order they first played. People are matched by id: renamed
/// between games, they stay one player. A team member is counted for the
/// visits they threw themselves; virtual opponents are left out.
List<GameStats> statsOf(Iterable<PlayedGame> games, StatsQuery query) {
  final tallies = <String, _Tally>{};
  for (final played in games) {
    if (!query._takes(played)) continue;
    final game = played.game;
    for (final side in game.players) {
      if (side.isTeam && query.participation == Participation.solo) continue;
      if (!side.isTeam && query.participation == Participation.team) continue;
      for (final person in side.throwers) {
        if (person.isBot) continue;
        final tally = tallies.putIfAbsent(person.id, _Tally.new)
          ..player = person;
        final part = _Part(
          side: side,
          person: person,
          won: game.winner?.id == side.id,
        );
        if (game.isFinished) {
          tally.gamesPlayed++;
          if (part.won) tally.gamesWon++;
        }
        if (played.matchWinner case final winner?) {
          tally.matchesPlayed++;
          if (winner.id == side.id) tally.matchesWon++;
        }
        switch (game) {
          case X01Game():
            tally.addX01(game, part);
          case CricketGame():
            tally.addCricket(game, part);
          default:
            if (game.isFinished) tally.addScore(_finalScore(game, side));
        }
      }
    }
  }
  return [for (final tally in tallies.values) tally.statsFor(query.kind)];
}

/// The game kinds [games] hold, in the order the app lists them.
List<GameKind> kindsPlayed(Iterable<PlayedGame> games) {
  final kinds = {for (final played in games) played.game.config.kind};
  return [
    for (final kind in GameKind.values)
      if (kinds.contains(kind)) kind,
  ];
}

/// Whether a team played in one of [games].
bool hasTeamGames(Iterable<PlayedGame> games) =>
    games.any((played) => played.game.players.any((side) => side.isTeam));

/// Whether lower scores win the games of [kind].
bool lowerScoreWins(GameKind kind) => kind == GameKind.golf;

/// What [side] ended a finished game on, when the game ends on a score.
int? _finalScore(Game game, Player side) {
  bool mine(Player player) => player.id == side.id;
  return switch (game) {
    ShanghaiGame() => game.scoreOf(side),
    HalveItGame(:final scores) =>
      scores.firstWhere((s) => mine(s.player)).points,
    GolfGame(:final scores) => scores.firstWhere((s) => mine(s.player)).strokes,
    Bobs27Game(:final scores) =>
      scores.firstWhere((s) => mine(s.player)).points,
    CountUpGame(:final scores) =>
      scores.firstWhere((s) => mine(s.player)).points,
    BaseballGame(:final scores) =>
      scores.firstWhere((s) => mine(s.player)).runs,
    X01Game() || CricketGame() || KillerGame() || AroundTheClockGame() => null,
  };
}

/// One person's part in one game: the side they played on and, in a
/// team, which of its turns were theirs.
class _Part {
  const _Part({required this.side, required this.person, required this.won});

  final Player side;
  final Player person;
  final bool won;

  bool get isSolo => side.throwers.length == 1;

  /// Those of the side's [visits], in order, that this person threw.
  Iterable<(int, T)> own<T>(List<T> visits) => side.thrownBy(person, visits);
}

class _Tally {
  late Player player;
  var gamesPlayed = 0;
  var gamesWon = 0;
  var matchesPlayed = 0;
  var matchesWon = 0;

  var points = 0;
  var darts = 0;
  var firstNinePoints = 0;
  var firstNineDarts = 0;
  int? bestVisit;
  var sixtyPlus = 0;
  var tons = 0;
  var ton40s = 0;
  var ton80s = 0;
  var dartsAtDouble = 0;
  var checkouts = 0;
  int? bestCheckout;
  int? fewestDartsToWin;
  var dartsInLegsWon = 0;
  var legsWonSolo = 0;

  var marks = 0;
  var rounds = 0;
  int? bestRound;
  var fiveMarkRounds = 0;
  var sevenMarkRounds = 0;
  var nineMarkRounds = 0;
  var bulls = 0;
  var sideRounds = 0;
  var sidePoints = 0;
  int? fewestRoundsToWin;

  var scoreSum = 0;
  var scores = 0;
  int? highestScore;
  int? lowestScore;

  void addX01(X01Game game, _Part part) {
    final score = game.scoreOf(part.side);
    final lastIndex = score.visits.length - 1;
    for (final (n, (i, visit)) in part.own(score.visits).indexed) {
      points += visit.points;
      darts += visit.darts;
      if (n < 3) {
        firstNinePoints += visit.points;
        firstNineDarts += visit.darts;
      }
      if (visit.points > (bestVisit ?? -1)) bestVisit = visit.points;
      if (visit.points >= 60) sixtyPlus++;
      if (visit.points >= 100) tons++;
      if (visit.points >= 140) ton40s++;
      if (visit.points == 180) ton80s++;
      final checkedOut = part.won && i == lastIndex;
      if (visit.dartsAtDouble case final atDouble?) {
        dartsAtDouble += atDouble;
        if (checkedOut) checkouts++;
      }
      if (checkedOut && visit.points > (bestCheckout ?? 0)) {
        bestCheckout = visit.points;
      }
    }
    // How fast a leg was won only says something of someone playing alone.
    if (!part.won || !part.isSolo) return;
    legsWonSolo++;
    dartsInLegsWon += score.dartsThrown;
    if (score.dartsThrown < (fewestDartsToWin ?? score.dartsThrown + 1)) {
      fewestDartsToWin = score.dartsThrown;
    }
  }

  void addCricket(CricketGame game, _Part part) {
    final score = game.scoreOf(part.side);
    for (final (_, round) in part.own(score.rounds)) {
      final hit = round.fold(0, (sum, d) => sum + (d.cricketMarks?.marks ?? 0));
      marks += hit;
      rounds++;
      if (hit > (bestRound ?? -1)) bestRound = hit;
      if (hit >= 5) fiveMarkRounds++;
      if (hit >= 7) sevenMarkRounds++;
      if (hit >= 9) nineMarkRounds++;
      bulls += round.where((d) => d.sector == Dart.bullSector).length;
    }
    if (!game.isFinished) return;
    sideRounds += score.rounds.length;
    sidePoints += score.points;
    if (part.won &&
        score.rounds.length < (fewestRoundsToWin ?? score.rounds.length + 1)) {
      fewestRoundsToWin = score.rounds.length;
    }
  }

  void addScore(int? score) {
    if (score == null) return;
    scoreSum += score;
    scores++;
    if (score > (highestScore ?? score - 1)) highestScore = score;
    if (score < (lowestScore ?? score + 1)) lowestScore = score;
  }

  double? _per(int total, int count) => count == 0 ? null : total / count;

  GameStats statsFor(GameKind kind) => switch (kind) {
    GameKind.x01 => X01Stats(
      player: player,
      gamesPlayed: gamesPlayed,
      gamesWon: gamesWon,
      average: averagePerVisit(points, darts),
      firstNineAverage: averagePerVisit(firstNinePoints, firstNineDarts),
      bestVisit: bestVisit,
      sixtyPlus: sixtyPlus,
      tons: tons,
      ton40s: ton40s,
      ton80s: ton80s,
      dartsAtDouble: dartsAtDouble,
      checkouts: checkouts,
      bestCheckout: bestCheckout,
      fewestDartsToWin: fewestDartsToWin,
      dartsPerLegWon: _per(dartsInLegsWon, legsWonSolo),
      dartsThrown: darts,
      matchesPlayed: matchesPlayed,
      matchesWon: matchesWon,
    ),
    GameKind.cricket => CricketStats(
      player: player,
      gamesPlayed: gamesPlayed,
      gamesWon: gamesWon,
      marksPerRound: perRound(marks, rounds),
      bestRound: bestRound,
      fiveMarkRounds: fiveMarkRounds,
      sevenMarkRounds: sevenMarkRounds,
      nineMarkRounds: nineMarkRounds,
      roundsPerGame: _per(sideRounds, gamesPlayed),
      fewestRoundsToWin: fewestRoundsToWin,
      pointsPerGame: _per(sidePoints, gamesPlayed),
      bulls: bulls,
      roundsPlayed: rounds,
    ),
    _ => ScoreStats(
      player: player,
      gamesPlayed: gamesPlayed,
      gamesWon: gamesWon,
      averageScore: _per(scoreSum, scores),
      bestScore: lowerScoreWins(kind) ? lowestScore : highestScore,
    ),
  };
}
