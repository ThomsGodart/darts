import 'package:darts_points_counter/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  test('a cancelled first game leaves a session with no game', () {
    final session = newSession()..startGame([alice, bob]);
    play(session, [60, 45]);

    expect(session.cancelGame(), isA<Accepted>());
    expect(session.state.games, isEmpty);
    expect(session.canUndo, isFalse);
  });

  test('a cancelled later game leaves the ones before as they ended', () {
    final session = newSession()
      ..startGame([alice, bob], config: const X01Config(startScore: 40));
    checkOut(session, 40, darts: 1);
    session.rematch();
    session.submitVisitTotal(20);
    final before = session.state.games.first;

    expect(session.cancelGame(), isA<Accepted>());

    expect(session.state.games, hasLength(1));
    expect(session.state.game!.winner, alice);
    expect(session.state.game, same(session.state.games.single));
    expect(
      (session.state.game! as X01Game).scores.first.visits,
      (before as X01Game).scores.first.visits,
    );
  });

  test('another game can start right after', () {
    final session = newSession()..startGame([alice, bob]);
    session.cancelGame();

    expect(
      session.startGame([bob, alice], config: const CricketConfig()),
      isA<Accepted>(),
    );
    expect(session.state.games, hasLength(1));
  });

  test('a game entered dart by dart is cancelled whole', () {
    final session = newSession()
      ..startGame([alice, bob], config: const CricketConfig());
    session
      ..throwDart(const Dart.treble(20))
      ..endVisit()
      ..throwDart(const Dart.single(19));

    session.cancelGame();
    expect(session.state.games, isEmpty);
  });

  test('there is nothing to cancel without a game in progress', () {
    final session = newSession();
    expect(session.cancelGame(), isA<Rejected>());

    session.startGame([alice], config: const X01Config(startScore: 40));
    checkOut(session, 40, darts: 1);
    expect(session.cancelGame(), isA<Rejected>(), reason: 'the game is over');

    session.endSession();
    expect(session.cancelGame(), isA<Rejected>());
  });
}
