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
  test('an X01 game shows each average', () {
    final session = newSession()..startGame([alice, bob]);
    play(session, [60, 45]);

    final stats = gameStats(session.state.game!);
    expect(stats.headings, ['moy.']);
    expect(rowsOf(stats), ['Alice: 60.0', 'Bob: 45.0']);
  });

  test('a cricket game shows points and MPR', () {
    final session = newSession()
      ..startGame([alice, bob], config: const CricketConfig());
    for (var i = 0; i < 3; i++) {
      session.throwDart(const Dart.treble(20));
    }

    final stats = gameStats(session.state.game!);
    expect(stats.headings, ['pts', 'MPR']);
    expect(rowsOf(stats), ['Alice: 120 9.0', 'Bob: 0 –']);
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
    expect(rowsOf(stats), ['Alice: 101.0 –', 'Bob: – 1.0']);
  });

  test('game over adds the session stats from the second game on', () {
    final session = newSession()
      ..startGame([alice], config: const X01Config(startScore: 101));
    checkOut(session, 101);
    expect(gameOverStats(session.state).headings, ['moy.']);

    session.rematch();
    checkOut(session, 101);
    final stats = gameOverStats(session.state);
    expect(stats.headings, ['moy.', 'moy. session']);
    expect(rowsOf(stats), ['Alice: 101.0 101.0']);
  });
}
