import 'package:darts_points_counter/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cricket_test.dart' show closeAll, cricketOf, standard, t20, visit;
import 'helpers.dart';

void main() {
  group('marks per round in a game', () {
    test('nothing before the first dart', () {
      final session = newSession()..startGame([alice, bob], config: standard);
      expect(cricketOf(session).marksPerRound(alice), isNull);
    });

    test('marks of a full visit over one round', () {
      final session = newSession()..startGame([alice, bob], config: standard);
      visit(session, [t20, const Dart.single(19), const Dart.treble(3)]);
      expect(cricketOf(session).marksPerRound(alice), 4);
      expect(cricketOf(session).marksPerRound(bob), isNull);
    });

    test('the visit in progress counts as a round', () {
      final session = newSession()..startGame([alice, bob], config: standard);
      session.throwDart(t20);
      expect(cricketOf(session).marksPerRound(alice), 3);
    });

    test('marks on a dead number and scoring marks still count', () {
      final session = newSession()..startGame([alice, bob], config: standard);
      visit(session, [t20]);
      visit(session, [t20]);
      visit(session, [t20, t20]); // 20 is dead: 6 marks, no points

      expect(cricketOf(session).scoreOf(alice).points, 0);
      expect(cricketOf(session).marksPerRound(alice), (3 + 6) / 2);
    });

    test('the winning visit counts as a whole round', () {
      final session = newSession()..startGame([alice, bob], config: standard);
      closeAll(session, 1); // 9 + 9 + 3 marks, the last visit in 2 darts
      expect(cricketOf(session).marksPerRound(alice), 21 / 3);
    });
  });

  group('a session mixing X01 and cricket', () {
    Session mixed() {
      final session = newSession()
        ..startGame([alice, bob], config: const X01Config(startScore: 40));
      checkOut(session, 40, darts: 1); // Alice: X01 average 120
      session.startGame([bob, alice], config: standard);
      visit(session); // Bob: 0 marks
      visit(session, [t20, t20]); // Alice: 6 marks
      return session;
    }

    test('the X01 average counts X01 games only', () {
      final state = mixed().state;
      expect(state.averageOf(alice), 120);
      expect(state.averageOf(bob), isNull);
    });

    test('marks per round count cricket games only', () {
      final state = mixed().state;
      expect(state.marksPerRoundOf(alice), 6);
      expect(state.marksPerRoundOf(bob), 0);
    });

    test('a player who played no cricket has no marks per round', () {
      final session = newSession()
        ..startGame([alice], config: const X01Config(startScore: 40));
      checkOut(session, 40, darts: 1);
      expect(session.state.marksPerRoundOf(alice), isNull);
    });
  });
}
