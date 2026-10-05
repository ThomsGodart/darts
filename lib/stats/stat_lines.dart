import '../session/session.dart';
import '../ui/average_label.dart';

/// A line of the stats table: what it counts, then its value for each
/// player, in the players' order.
typedef StatLine = (String label, List<String> values);

String _count(int? value) => value == null ? '–' : '$value';

/// "3 (60 %)", or "0" before the first finished game.
String _wins(GameStats stats) => switch (stats.winRate) {
  null => '${stats.gamesWon}',
  final rate => '${stats.gamesWon} (${(100 * rate).round()} %)',
};

/// The lines of the table for [stats], everyone's stats over one kind of
/// game: every stat that says something of that game.
List<StatLine> statLines(List<GameStats> stats) {
  List<String> each<T extends GameStats>(String Function(T) valueOf) => [
    for (final s in stats) valueOf(s as T),
  ];
  final shared = <StatLine>[
    ('Parties terminées', each<GameStats>((s) => '${s.gamesPlayed}')),
    ('Victoires', each<GameStats>(_wins)),
  ];
  return switch (stats.firstOrNull) {
    null => const [],
    X01Stats() => [
      ...shared,
      ('Moyenne', each<X01Stats>((s) => averageLabel(s.average))),
      (
        'Moyenne des 9 premières',
        each<X01Stats>((s) => averageLabel(s.firstNineAverage)),
      ),
      ('Meilleure volée', each<X01Stats>((s) => _count(s.bestVisit))),
      ('60+', each<X01Stats>((s) => '${s.sixtyPlus}')),
      ('100+', each<X01Stats>((s) => '${s.tons}')),
      ('140+', each<X01Stats>((s) => '${s.ton40s}')),
      ('180', each<X01Stats>((s) => '${s.ton80s}')),
      (
        'Checkout',
        each<X01Stats>(
          (s) => switch (s.checkoutRate) {
            null => '–',
            final rate =>
              '${(100 * rate).round()} % (${s.checkouts}/${s.dartsAtDouble})',
          },
        ),
      ),
      ('Meilleure finition', each<X01Stats>((s) => _count(s.bestCheckout))),
      (
        'Manche la plus courte',
        each<X01Stats>(
          (s) => switch (s.fewestDartsToWin) {
            null => '–',
            final darts => '$darts fl.',
          },
        ),
      ),
      (
        'Fléchettes par manche gagnée',
        each<X01Stats>((s) => averageLabel(s.dartsPerLegWon)),
      ),
      ('Fléchettes lancées', each<X01Stats>((s) => '${s.dartsThrown}')),
      // Only once someone played a match of several legs to its end.
      if (stats.any((s) => (s as X01Stats).matchesPlayed > 0)) ...[
        ('Matchs joués', each<X01Stats>((s) => '${s.matchesPlayed}')),
        ('Matchs gagnés', each<X01Stats>((s) => '${s.matchesWon}')),
      ],
    ],
    CricketStats() => [
      ...shared,
      ('MPR', each<CricketStats>((s) => averageLabel(s.marksPerRound))),
      (
        'Meilleur round',
        each<CricketStats>(
          (s) => switch (s.bestRound) {
            null => '–',
            final marks => '$marks marques',
          },
        ),
      ),
      ('5 marques et +', each<CricketStats>((s) => '${s.fiveMarkRounds}')),
      ('7 marques et +', each<CricketStats>((s) => '${s.sevenMarkRounds}')),
      ('9 marques', each<CricketStats>((s) => '${s.nineMarkRounds}')),
      (
        'Rounds par partie',
        each<CricketStats>((s) => averageLabel(s.roundsPerGame)),
      ),
      (
        'Partie la plus courte',
        each<CricketStats>(
          (s) => switch (s.fewestRoundsToWin) {
            null => '–',
            final rounds => '$rounds rounds',
          },
        ),
      ),
      (
        'Points par partie',
        each<CricketStats>((s) => averageLabel(s.pointsPerGame)),
      ),
      ('Bulls', each<CricketStats>((s) => '${s.bulls}')),
      ('Rounds joués', each<CricketStats>((s) => '${s.roundsPlayed}')),
    ],
    ScoreStats() => [
      ...shared,
      // Killer and Around the Clock end on no score.
      if (stats.any((s) => (s as ScoreStats).averageScore != null)) ...[
        ('Score moyen', each<ScoreStats>((s) => averageLabel(s.averageScore))),
        ('Meilleur score', each<ScoreStats>((s) => _count(s.bestScore))),
      ],
    ],
  };
}
