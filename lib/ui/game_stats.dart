import '../session/session.dart';
import 'average_label.dart';

/// A stats table as shown after a game and in the history: column
/// headings, then each player's values, already formatted.
typedef StatsTable = ({
  List<String> headings,
  List<(Player, List<String>)> rows,
});

/// What [game] says about each of its players.
StatsTable gameStats(Game game) => switch (game) {
  X01Game(:final scores) => (
    headings: const ['moy.'],
    rows: [
      for (final score in scores)
        (score.player, [averageLabel(score.threeDartAverage)]),
    ],
  ),
  CricketGame(:final scores) => (
    headings: const ['pts', 'MPR'],
    rows: [
      for (final score in scores)
        (
          score.player,
          ['${score.points}', averageLabel(game.marksPerRound(score.player))],
        ),
    ],
  ),
  ShanghaiGame(:final scores) => (
    headings: const ['pts'],
    rows: [
      for (final score in scores) (score.player, ['${score.points}']),
    ],
  ),
  KillerGame(:final scores) => (
    headings: const ['n°', 'vies'],
    rows: [
      for (final score in scores)
        (score.player, ['${score.number ?? '–'}', killerLivesLabel(score)]),
    ],
  ),
};

/// "3", or "OUT" once the player has no life left.
String killerLivesLabel(KillerScore score) =>
    score.isOut ? 'OUT' : '${score.lives ?? 0}';

/// What the whole session says about each of its players: one column per
/// stat of a game type played in it, "–" for who did not play that type.
StatsTable sessionStats(SessionState session) {
  final x01 = session.games.any((g) => g is X01Game);
  final cricket = session.games.any((g) => g is CricketGame);
  return (
    headings: [if (x01) 'moy.', if (cricket) 'MPR'],
    rows: [
      for (final player in session.players)
        (
          player,
          [
            if (x01) averageLabel(session.averageOf(player)),
            if (cricket) averageLabel(session.marksPerRoundOf(player)),
          ],
        ),
    ],
  );
}

/// The end-of-game table: the current game's stats, followed from the
/// second game on by the session's, so a cricket game still shows the X01
/// average and the other way round.
StatsTable gameOverStats(SessionState session) {
  final game = gameStats(session.game!);
  if (session.games.length < 2) return game;
  final overall = sessionStats(session);
  List<String> overallOf(Player player) =>
      overall.rows.firstWhere((row) => row.$1.id == player.id).$2;
  return (
    headings: [
      ...game.headings,
      for (final heading in overall.headings) '$heading session',
    ],
    rows: [
      for (final (player, values) in game.rows)
        (player, [...values, ...overallOf(player)]),
    ],
  );
}
