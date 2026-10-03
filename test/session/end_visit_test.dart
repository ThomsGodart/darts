import 'package:darts_points_counter/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  test('ending a visit after one dart passes the turn, misses filled in', () {
    final session = newSession()..startGame([alice, bob]);
    session.throwDart(const Dart.treble(20));

    expect(session.endVisit(), isA<Accepted>());

    final game = session.state.x01!;
    expect(game.activePlayer, bob);
    expect(game.dartsInVisit, isEmpty);
    expect(game.scoreOf(alice).remaining, 441);
    expect(game.scoreOf(alice).lastVisit!.darts, dartsPerVisit);
  });

  test('one undo takes the whole end of visit back', () {
    final session = newSession()
      ..startGame([alice, bob], config: const CricketConfig());
    session.throwDart(const Dart.single(20));
    final before = scoreboardOf(session);

    session.endVisit();
    expect(session.undo(), isA<Accepted>());

    expect(scoreboardOf(session), before);
    expect(session.state.game!.dartsInVisit, [const Dart.single(20)]);
  });

  test('a visit can be ended before its first dart', () {
    final session = newSession()
      ..startGame([alice, bob], config: const ShanghaiConfig());

    expect(session.endVisit(), isA<Accepted>());

    expect(session.state.game!.activePlayer, bob);
    expect(session.state.game!.visitsPlayed, 1);
  });

  test('no visit to end outside a game in progress', () {
    final session = newSession();
    expect(session.endVisit(), isA<Rejected>());

    session.startGame([
      alice,
      bob,
      const Player(id: 'c', name: 'Chloé'),
    ], config: const KillerConfig());
    // Numbers are still being assigned: nobody is throwing yet.
    expect(session.endVisit(), isA<Rejected>());
  });
}
