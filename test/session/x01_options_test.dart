import 'package:darts_points_counter/session/checkout.dart';
import 'package:darts_points_counter/session/event_codec.dart';
import 'package:darts_points_counter/session/events.dart';
import 'package:darts_points_counter/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group('master-out', () {
    const config = X01Config(startScore: 60, outRule: OutRule.master);

    test('a treble finishes, as a double does', () {
      final onTreble = newSession()..startGame([alice], config: config);
      onTreble.throwDart(const Dart.treble(20));
      expect(onTreble.state.game!.winner, alice);

      final onDouble = newSession()
        ..startGame([
          alice,
        ], config: const X01Config(startScore: 40, outRule: OutRule.master));
      onDouble.throwDart(const Dart.double(20));
      expect(onDouble.state.game!.winner, alice);
    });

    test('a single does not: the visit busts', () {
      final session = newSession()
        ..startGame([
          alice,
          bob,
        ], config: const X01Config(startScore: 20, outRule: OutRule.master));
      session
        ..throwDart(const Dart.single(20))
        ..endVisit();

      final game = session.state.x01!;
      expect(game.winner, isNull);
      expect(game.scoreOf(alice).remaining, 20);
      expect(game.scoreOf(alice).lastVisit!.isBust, isTrue);
    });

    test('leaving 1 busts; a total can check out what a treble finishes', () {
      final session = newSession()..startGame([alice, bob], config: config);
      session.submitVisitTotal(59);
      expect(session.state.x01!.scoreOf(alice).lastVisit!.isBust, isTrue);

      session.submitVisitTotal(0);
      expect(session.submitVisitTotal(60, dartsAtCheckout: 1), isA<Accepted>());
      expect(session.state.game!.winner, alice);
    });

    test('a checkout route may end on a treble', () {
      expect(suggestCheckout(57, 1, OutRule.master), [const Dart.treble(19)]);
      expect(suggestCheckout(57, 1, OutRule.double), isNull);
    });
  });

  group('double-in', () {
    const config = X01Config(startScore: 101, doubleIn: true);

    test('darts before the first double score nothing', () {
      final session = newSession()..startGame([alice, bob], config: config);
      session
        ..throwDart(const Dart.treble(20))
        ..throwDart(const Dart.single(20));
      expect(session.state.x01!.activeRemaining, 101);

      session
        ..throwDart(const Dart.double(10))
        ..endVisit();
      final score = session.state.x01!.scoreOf(alice);
      expect(score.remaining, 81);
      expect(score.isIn, isTrue);
    });

    test('once in, every dart scores, in later visits too', () {
      final session = newSession()..startGame([alice, bob], config: config);
      session
        ..throwDart(const Dart.double(10))
        ..throwDart(const Dart.single(20))
        ..throwDart(Dart.miss)
        ..endVisit();
      expect(session.state.x01!.scoreOf(alice).remaining, 61);

      session.endVisit(); // Bob, still out
      expect(session.state.x01!.scoreOf(bob).isIn, isFalse);
      session.throwDart(const Dart.single(20));
      expect(session.state.x01!.activeRemaining, 41);
    });

    test('a visit entered as a total gets the player in when it scores', () {
      final session = newSession()..startGame([alice, bob], config: config);
      session.submitVisitTotal(0);
      expect(session.state.x01!.scoreOf(alice).isIn, isFalse);
      session.submitVisitTotal(40);
      expect(session.state.x01!.scoreOf(bob).isIn, isTrue);
    });

    test('without double-in everyone is in from the start', () {
      final session = newSession()..startGame([alice]);
      expect(session.state.x01!.scoreOf(alice).isIn, isTrue);
    });
  });

  test('any start score above 1 can be played; 170 and 701 are offered', () {
    expect(X01Config.offeredStartScores, [170, 301, 501, 701]);
    expect(const X01Config(startScore: 1001).isValid, isTrue);
    expect(const X01Config(startScore: 1).isValid, isFalse);
  });

  test('the new rules are stored, and old games read without them', () {
    const config = X01Config(
      startScore: 701,
      outRule: OutRule.master,
      doubleIn: true,
    );
    final encoded = encodeEvent(
      const GameStarted(players: [alice], config: config),
    );
    expect(encoded.payload['outRule'], 'master');
    expect(
      (decodeEvent(encoded.type, encoded.payload) as GameStarted).config,
      config,
    );

    final old = Map.of(encoded.payload)..remove('doubleIn');
    expect(
      (decodeEvent(encoded.type, old) as GameStarted).config,
      const X01Config(startScore: 701, outRule: OutRule.master),
    );
  });
}
