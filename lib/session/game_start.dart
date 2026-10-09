import 'game_config.dart';
import 'player.dart';

/// Why a game cannot start.
enum StartProblem {
  /// Nobody is to play.
  noPlayers,

  /// More sides than a game takes.
  tooManyPlayers,

  /// Fewer sides than the rules ask for.
  tooFewPlayers,

  /// Someone holds two of the scores.
  samePlayerTwice,

  /// The rules themselves cannot be played.
  invalidRules,

  /// A virtual opponent, alone or in a team, in a game entered dart by
  /// dart: nobody would throw for it.
  botCannotPlay,
}

/// What keeps [sides], in throwing order, from starting a game with
/// [config]; null when nothing does. The one place that says so: the
/// session refuses what this refuses, and the setup asks before offering
/// to start.
StartProblem? startProblem(List<Player> sides, GameConfig config) {
  if (sides.isEmpty) return StartProblem.noPlayers;
  if (sides.length > maxPlayers) return StartProblem.tooManyPlayers;
  if (sides.length < config.minPlayers) return StartProblem.tooFewPlayers;
  if (sides.map((side) => side.id).toSet().length != sides.length) {
    return StartProblem.samePlayerTwice;
  }
  if (!config.isValid) return StartProblem.invalidRules;
  final throwers = sides.expand((side) => side.throwers);
  if (!config.takesTotals && throwers.any((thrower) => thrower.isBot)) {
    return StartProblem.botCannotPlay;
  }
  return null;
}
