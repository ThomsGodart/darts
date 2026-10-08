import 'package:darts_points_counter/session/session.dart';
import 'package:darts_points_counter/ui/game_stats.dart';
import 'package:flutter_test/flutter_test.dart';

import '../session/helpers.dart';

/// "Alice: 60.0 45.0", a row per player.
List<String> rowsOf(StatsTable stats) => [
  for (final (player, values) in stats.rows)
    '${player.name}: ${values.join(' ')}',
];

void main() {
  test('an X01 game shows each average and best visit', () {
    final session = newSession()..startGame([alice, bob]);
    play(session, [60, 45, 100, 45]);

    final stats = gameStats(session.state.game!);
    expect(stats.headings, ['moy.', 'max']);
    expect(rowsOf(stats), ['Alice: 80.0 100', 'Bob: 45.0 45']);
  });

  test('a cricket game shows points and MPR', () {
    final session = newSession()
      ..startGame([alice, bob], config: const CricketConfig());
    for (var i = 0; i < 3; i++) {
      session.throwDart(const Dart.treble(20));
    }

    final stats = gameStats(session.state.game!);
    expect(stats.headings, ['pts', 'MPR']);
    expect(rowsOf(stats), ['Alice: 120 9.00', 'Bob: 0 –']);
  });

  test('a Killer game shows numbers and lives, OUT without any', () {
    const chloe = Player(id: 'chloe', name: 'Chloé');
    final session = newSession()
      ..startGame([alice, bob, chloe], config: const KillerConfig())
      ..assignNumber(1)
      ..assignNumber(2)
      ..assignNumber(3)
      // Alice becomes Killer on her own double, then takes Bob's lives.
      ..throwDart(const Dart.double(1))
      ..throwDart(const Dart.double(2))
      ..throwDart(const Dart.double(2))
      ..endVisit()
      ..endVisit()
      ..endVisit()
      ..throwDart(const Dart.double(2));

    final stats = gameStats(session.state.game!);
    expect(stats.headings, ['n°', 'vies']);
    expect(rowsOf(stats), ['Alice: 1 3', 'Bob: 2 OUT', 'Chloé: 3 3']);
  });

  test('the session shows a column per game type played, – otherwise', () {
    final session = newSession()
      ..startGame([alice], config: const X01Config(startScore: 101));
    checkOut(session, 101);
    expect(sessionStats(session.state).headings, ['moy.']);

    session.startGame([bob], config: const CricketConfig());
    session.throwDart(const Dart.single(20));

    final stats = sessionStats(session.state);
    expect(stats.headings, ['moy.', 'MPR']);
    expect(rowsOf(stats), ['Alice: 101.0 –', 'Bob: – 1.00']);
  });

  test('game over adds the session stats from the second game on', () {
    final session = newSession()
      ..startGame([alice], config: const X01Config(startScore: 101));
    checkOut(session, 101);
    expect(gameOverStats(session.state).headings, ['moy.', 'max']);

    session.rematch();
    checkOut(session, 101);
    final stats = gameOverStats(session.state);
    expect(stats.headings, ['moy.', 'max', 'moy. session']);
    expect(rowsOf(stats), ['Alice: 101.0 101 101.0']);
  });

  test('game over shows the session stat of its own kind of game only', () {
    final session = newSession()
      ..startGame([alice], config: const CricketConfig())
      ..throwDart(const Dart.treble(20))
      ..endSession();
    final mixed = newSession()
      ..startGame([alice, bob], config: const CricketConfig());
    for (final number in cricketNumbers) {
      mixed.throwDart(
        number == Dart.bullSector ? Dart.bull : Dart.treble(number),
      );
      if (number == Dart.bullSector) mixed.throwDart(Dart.outerBull);
      if (mixed.state.game!.visitIsOver) {
        mixed
          ..endVisit()
          ..endVisit();
      }
    }
    expect(mixed.state.game!.winner, alice);
    expect(gameLengthLabel(mixed.state.game!), '3 rounds');
    expect(gameLengthLabel(session.state.game!), isNull);

    mixed.startGame([alice, bob], config: const X01Config(startScore: 101));
    checkOut(mixed, 101);
    final stats = gameOverStats(mixed.state);
    expect(stats.headings, ['moy.', 'max', 'moy. session']);
    expect(gameLengthLabel(mixed.state.game!), '1 volée · 3 fléchettes');

    mixed.startGame([alice, bob], config: const CountUpConfig(rounds: 8));
    for (var i = 0; i < 16; i++) {
      mixed.submitVisitTotal(60);
    }
    expect(gameOverStats(mixed.state).headings, ['pts']);
    expect(gameLengthLabel(mixed.state.game!), '8 manches');
  });
}
