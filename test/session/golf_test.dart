import 'package:darts_points_counter/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const golf = GolfConfig();
const miss = Dart.miss;

GolfGame golfOf(Session session) => session.state.game! as GolfGame;

void main() {
  test('a new game: hole 1, nobody has a stroke', () {
    final session = newSession()..startGame([alice, bob], config: golf);
    final game = golfOf(session);

    expect(game.currentHole, 1);
    expect(game.scoreOf(alice).strokes, 0);
    expect(game.activePlayer, alice);
  });

  test('nine or eighteen holes, nothing else', () {
    expect(const GolfConfig().holes, 9);
    expect(const GolfConfig(holes: 18).isValid, isTrue);
    expect(const GolfConfig(holes: 12).isValid, isFalse);
  });

  test('strokes: double 1, treble 2, single 3, anything else 5', () {
    expect(golfStrokes(const Dart.double(4), hole: 4), 1);
    expect(golfStrokes(const Dart.treble(4), hole: 4), 2);
    expect(golfStrokes(const Dart.single(4), hole: 4), 3);
    expect(golfStrokes(const Dart.double(5), hole: 4), 5);
    expect(golfStrokes(miss, hole: 4), 5);
    expect(golfStrokes(null, hole: 4), 5);
  });

  test('the last dart thrown is the one that counts', () {
    final session = newSession()..startGame([alice, bob], config: golf);
    session
      ..throwDart(const Dart.double(1))
      ..throwDart(const Dart.single(1))
      ..throwDart(miss);

    expect(golfOf(session).scoreOf(alice).holeStrokes, [5]);
    expect(golfOf(session).activePlayer, bob);
  });

  test('a player may stop on a dart they like', () {
    final session = newSession()..startGame([alice, bob], config: golf);
    session
      ..throwDart(const Dart.single(1))
      ..throwDart(const Dart.double(1));
    expect(session.endVisit(), isA<Accepted>());

    expect(golfOf(session).scoreOf(alice).holeStrokes, [1]);
    expect(golfOf(session).activePlayer, bob);
  });

  test('stopping before any dart costs a miss', () {
    final session = newSession()..startGame([alice, bob], config: golf);
    session.endVisit();

    expect(golfOf(session).scoreOf(alice).strokes, 5);
  });

  test('everyone plays a hole before the next one', () {
    final session = newSession()..startGame([alice, bob], config: golf);
    session.endVisit();
    expect(golfOf(session).currentHole, 1);
    session.endVisit();
    expect(golfOf(session).currentHole, 2);
    expect(golfOf(session).activePlayer, alice);
  });

  test('after the last hole, the fewest strokes win', () {
    final session = newSession()..startGame([alice, bob], config: golf);
    for (var hole = 1; hole <= 9; hole++) {
      // Alice singles every hole; Bob doubles them.
      session
        ..throwDart(Dart.single(hole))
        ..endVisit();
      expect(golfOf(session).isFinished, isFalse);
      session
        ..throwDart(Dart.double(hole))
        ..endVisit();
    }

    final game = golfOf(session);
    expect(game.scoreOf(alice).strokes, 27);
    expect(game.scoreOf(bob).strokes, 9);
    expect(game.winner, bob);
    expect(session.throwDart(miss), isA<Rejected>());
  });

  test('a tie goes to whoever threw first', () {
    final session = newSession()..startGame([alice, bob], config: golf);
    for (var i = 0; i < 18; i++) {
      session.endVisit();
    }
    expect(golfOf(session).winner, alice);
  });

  test('eighteen holes run to hole 18', () {
    final session = newSession()
      ..startGame([alice], config: const GolfConfig(holes: 18));
    for (var i = 0; i < 17; i++) {
      session.endVisit();
    }
    expect(golfOf(session).currentHole, 18);
    expect(golfOf(session).isFinished, isFalse);
    session.endVisit();
    expect(golfOf(session).isFinished, isTrue);
  });

  test('one undo takes an ended visit back', () {
    final session = newSession()..startGame([alice, bob], config: golf);
    session.throwDart(const Dart.treble(1));
    final before = scoreboardOf(session);

    session.endVisit();
    session.undo();
    expect(scoreboardOf(session), before);
  });
}
