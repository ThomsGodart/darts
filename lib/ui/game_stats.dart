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
    headings: const ['moy.', 'max'],
    rows: [
      for (final score in scores)
        (
          score.player,
          [
            averageLabel(score.threeDartAverage),
            '${score.visits.fold(0, (best, v) => v.points > best ? v.points : best)}',
          ],
        ),
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
  HalveItGame(:final scores) => (
    headings: const ['pts'],
    rows: [
      for (final score in scores) (score.player, ['${score.points}']),
    ],
  ),
  GolfGame(:final scores) => (
    headings: const ['coups'],
    rows: [
      for (final score in scores) (score.player, ['${score.strokes}']),
    ],
  ),
  AroundTheClockGame(:final scores) => (
    headings: const ['cibles'],
    rows: [
      for (final score in scores) (score.player, ['${score.hits}']),
    ],
  ),
  Bobs27Game(:final scores) => (
    headings: const ['pts'],
    rows: [
      for (final score in scores) (score.player, ['${score.points}']),
    ],
  ),
  CountUpGame(:final scores) => (
    headings: const ['pts'],
    rows: [
      for (final score in scores) (score.player, ['${score.points}']),
    ],
  ),
  BaseballGame(:final scores) => (
    headings: const ['runs'],
    rows: [
      for (final score in scores) (score.player, ['${score.runs}']),
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

/// The stats of the game just finished and, from the second game of the
/// session on, the same players' session stat for that kind of game. A
/// stat of another game played in the session has no business here: an
/// X01 leg shows no MPR.
StatsTable gameOverStats(SessionState session) {
  final current = session.game!;
  final game = gameStats(current);
  if (session.games.length < 2) return game;
  final (String heading, String Function(Player) valueOf)? overall =
      switch (current) {
        X01Game() => (
          'moy. session',
          (player) => averageLabel(session.averageOf(player)),
        ),
        CricketGame() => (
          'MPR session',
          (player) => averageLabel(session.marksPerRoundOf(player)),
        ),
        _ => null,
      };
  if (overall == null) return game;
  return (
    headings: [...game.headings, overall.$1],
    rows: [
      for (final (player, values) in game.rows)
        (player, [...values, overall.$2(player)]),
    ],
  );
}

/// How long a finished game took, in what its players count: "5 volées ·
/// 13 fléchettes" for the winner of an X01, "12 rounds" of Cricket, "8
/// manches" of a game by rounds. Null while the game is unfinished, and
/// for Killer, where players drop out along the way.
String? gameLengthLabel(Game game) {
  final winner = game.winner;
  if (winner == null) return null;
  String count(int n, String one, String many) => '$n ${n == 1 ? one : many}';
  return switch (game) {
    X01Game() => [
      count(game.scoreOf(winner).visitsPlayed, 'volée', 'volées'),
      count(game.scoreOf(winner).dartsThrown, 'fléchette', 'fléchettes'),
    ].join(' · '),
    CricketGame() => count(game.round, 'round', 'rounds'),
    KillerGame() => null,
    _ => count(
      (game.visitsPlayed / game.players.length).ceil(),
      'manche',
      'manches',
    ),
  };
}
