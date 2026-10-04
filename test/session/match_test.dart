import 'package:darts_points_counter/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// A leg of [config] won by whoever throws first in it.
void legToFirstThrower(Session session, X01Config config) {
  checkOut(session, config.startScore, darts: 3);
}

/// Legs on 40 double-out: any first visit of 40 checks out.
const bestOf5 = X01Config(startScore: 40, legsToWin: 3);

void main() {
  test('a single leg is not a match', () {
    final session = newSession()
      ..startGame([alice, bob], config: const X01Config(startScore: 40));
    expect(session.state.match, isNull);
    expect(const X01Config().legsToWin, 1);
    expect(const X01Config().setsToWin, 1);
  });

  test('a match starts level', () {
    final session = newSession()..startGame([alice, bob], config: bestOf5);
    final match = session.state.match!;

    expect(match.legsOf(alice), 0);
    expect(match.legsOf(bob), 0);
    expect(match.winner, isNull);
  });

  test('each leg won counts; the rematch alternates who throws first', () {
    final session = newSession()..startGame([alice, bob], config: bestOf5);
    legToFirstThrower(session, bestOf5); // Alice
    expect(session.state.match!.legsOf(alice), 1);
    expect(session.state.match!.winner, isNull);

    session.rematch();
    expect(session.state.game!.activePlayer, bob);
    legToFirstThrower(session, bestOf5); // Bob
    session.rematch();
    legToFirstThrower(session, bestOf5); // Alice

    final match = session.state.match!;
    expect(match.legsOf(alice), 2);
    expect(match.legsOf(bob), 1);
    expect(match.winner, isNull);
  });

  test('the first to the legs asked wins the match', () {
    final session = newSession()..startGame([alice, bob], config: bestOf5);
    for (var leg = 0; leg < 5; leg++) {
      legToFirstThrower(session, bestOf5);
      if (session.state.match!.winner != null) break;
      session.rematch();
    }

    final match = session.state.match!;
    expect(match.winner, alice);
    expect(match.legsOf(alice), 3);
    expect(match.legsOf(bob), 2);
  });

  test('a rematch after a decided match starts a new one', () {
    const firstTo1Twice = X01Config(startScore: 40, legsToWin: 2);
    final session = newSession()
      ..startGame([alice, bob], config: firstTo1Twice);
    legToFirstThrower(session, firstTo1Twice); // Alice 1-0
    session.rematch();
    session.submitVisitTotal(0); // Bob
    checkOut(session, 40); // Alice 2-0: match
    expect(session.state.match!.winner, alice);

    session.rematch();
    final match = session.state.match!;
    expect(match.winner, isNull);
    expect(match.legsOf(alice), 0);
  });

  test('other rules or other players start a new match', () {
    final session = newSession()..startGame([alice, bob], config: bestOf5);
    legToFirstThrower(session, bestOf5);
    session.startGame([bob, alice], config: bestOf5);
    expect(session.state.match!.legsOf(alice), 1, reason: 'same match');

    legToFirstThrower(session, bestOf5);
    session.startGame([
      alice,
      bob,
      const Player(id: 'c', name: 'Chloé'),
    ], config: bestOf5);
    expect(session.state.match!.legsOf(alice), 0, reason: 'someone joined');
  });

  test('with sets, legs win sets and sets win the match', () {
    const config = X01Config(startScore: 40, legsToWin: 2, setsToWin: 2);
    final session = newSession()..startGame([alice], config: config);
    final seen = <String>[];
    for (var leg = 0; leg < 4; leg++) {
      legToFirstThrower(session, config);
      final match = session.state.match!;
      seen.add('${match.setsOf(alice)}/${match.legsOf(alice)}');
      if (match.winner != null) break;
      session.rematch();
    }

    // Sets / legs of the set in progress; the last set keeps its legs.
    expect(seen, ['0/1', '1/0', '1/1', '2/2']);
    expect(session.state.match!.winner, alice);
  });

  test('undo takes a won leg back off the match', () {
    final session = newSession()..startGame([alice, bob], config: bestOf5);
    legToFirstThrower(session, bestOf5);
    session.undo();
    expect(session.state.match!.legsOf(alice), 0);
  });

  test('only some leg and set counts can be played', () {
    expect(const X01Config(legsToWin: 3, setsToWin: 2).isValid, isTrue);
    expect(const X01Config(legsToWin: 0).isValid, isFalse);
    expect(const X01Config(setsToWin: 0).isValid, isFalse);
  });
}
