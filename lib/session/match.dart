import 'game_config.dart';
import 'player.dart';
import 'state.dart';

/// Where a match stands: X01 legs chained with the same players and
/// rules, won by legs, or by sets of legs.
class MatchScore {
  const MatchScore({
    required this.config,
    required this.players,
    required this.legs,
    required this.sets,
    this.winner,
  });

  final X01Config config;

  /// The players, in the throwing order of the latest leg.
  final List<Player> players;

  /// Legs and sets won so far, by player id; absent means none.
  final Map<String, int> legs;
  final Map<String, int> sets;

  /// Who won the match; null while it is still open.
  final Player? winner;

  /// Legs [player] won in the set in progress (in the match, without
  /// sets). Once the match is won, the legs of its last set.
  int legsOf(Player player) => legs[player.id] ?? 0;

  /// Sets [player] won.
  int setsOf(Player player) => sets[player.id] ?? 0;
}

/// The match the latest of [games] is a leg of, if any.
///
/// Nothing in the journal says where a match starts: it is the latest run
/// of X01 games with the same rules and the same players, in any order,
/// and a decided match ends its run. So "Rejouer" after a won leg plays
/// the next leg, and after a won match starts a new one.
MatchScore? matchOf(List<Game> games) {
  final latest = games.lastOrNull;
  if (latest is! X01Game || !latest.config.isMatch) return null;
  final config = latest.config;
  final who = {for (final player in latest.players) player.id};

  // The run of legs the latest game belongs to, oldest first.
  final legs = <X01Game>[];
  for (final game in games.reversed) {
    if (game is! X01Game || game.config != config) break;
    final ids = {for (final player in game.players) player.id};
    if (ids.length != who.length || !ids.containsAll(who)) break;
    legs.insert(0, game);
  }

  var legsWon = <String, int>{};
  var setsWon = <String, int>{};
  Player? matchWinner;
  for (final leg in legs) {
    if (matchWinner != null) {
      // The match before this leg was decided: this leg opens a new one.
      legsWon = {};
      setsWon = {};
      matchWinner = null;
    }
    final winner = leg.winner;
    if (winner == null) continue;
    final legsNow = legsWon[winner.id] = (legsWon[winner.id] ?? 0) + 1;
    if (legsNow < config.legsToWin) continue;
    final setsNow = setsWon[winner.id] = (setsWon[winner.id] ?? 0) + 1;
    if (setsNow >= config.setsToWin) {
      matchWinner = winner;
    } else {
      legsWon = {};
    }
  }
  return MatchScore(
    config: config,
    players: latest.players,
    legs: legsWon,
    sets: setsWon,
    winner: matchWinner,
  );
}
