import 'dart:math';

import 'package:darts_points_counter/session/event_codec.dart';
import 'package:darts_points_counter/session/events.dart';
import 'package:darts_points_counter/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const chloe = Player(id: 'chloe', name: 'Chloé');
const dan = Player(id: 'dan', name: 'Dan');

void main() {
  group('virtual opponent', () {
    test('a bot is a player with an average to throw to', () {
      final bot = Player.bot(60);
      expect(bot.isBot, isTrue);
      expect(bot.name, 'Bot 60');
      expect(alice.isBot, isFalse);
      expect(Player.bot(60), Player.bot(60));
    });

    test('far from a finish, its visits average what was asked', () {
      for (final average in [40, 60, 80]) {
        final random = Random(average);
        var total = 0;
        const visits = 4000;
        for (var i = 0; i < visits; i++) {
          final score = botCountUpVisit(average, random);
          expect(isPossibleVisitTotal(score), isTrue, reason: '$score');
          total += score;
        }
        expect(total / visits, closeTo(average, 4), reason: 'bot $average');
      }
    });

    test('every visit it enters is accepted, and it finishes its legs', () {
      for (final outRule in OutRule.values) {
        for (var seed = 0; seed < 30; seed++) {
          final random = Random(seed);
          final bot = Player.bot(50);
          final session = newSession()
            ..startGame([bot], config: X01Config(outRule: outRule));
          var visits = 0;
          while (!session.state.game!.isFinished) {
            final visit = botVisit(session.state.x01!, random);
            expect(
              session.submitVisitTotal(
                visit.score,
                dartsAtCheckout: visit.dartsAtCheckout,
              ),
              isA<Accepted>(),
              reason: '$outRule seed $seed: $visit',
            );
            expect(++visits, lessThan(200), reason: 'never finishes');
          }
          expect(session.state.game!.winner, bot);
        }
      }
    });

    test('a stronger bot finishes 501 in fewer darts', () {
      double dartsToFinish(int average) {
        var darts = 0;
        const legs = 200;
        final random = Random(1);
        for (var leg = 0; leg < legs; leg++) {
          final session = newSession()..startGame([Player.bot(average)]);
          while (!session.state.game!.isFinished) {
            final visit = botVisit(session.state.x01!, random);
            session.submitVisitTotal(
              visit.score,
              dartsAtCheckout: visit.dartsAtCheckout,
            );
          }
          darts += session.state.x01!.scores.single.dartsThrown;
        }
        return darts / legs;
      }

      expect(dartsToFinish(80), lessThan(dartsToFinish(40)));
    });

    test('bots are left out of the stats', () {
      final session = newSession()..startGame([alice, Player.bot(60)]);
      play(session, [60, 60]);
      expect(
        [
          for (final s in playerStats([session.state])) s.player,
        ],
        [alice],
      );
    });
  });

  group('teams', () {
    final ab = Player.team(const [alice, bob]);
    final cd = Player.team(const [chloe, dan]);

    test('a team is one side, named after its members', () {
      expect(ab.isTeam, isTrue);
      expect(ab.name, 'Alice & Bob');
      expect(ab.members, [alice, bob]);
      expect(alice.isTeam, isFalse);
      expect(Player.team(const [alice, bob]), ab);
    });

    test('a team shares one score; its members take turns to throw', () {
      final session = newSession()..startGame([ab, cd]);
      final throwers = <String>[];
      for (final score in [60, 45, 100, 26]) {
        throwers.add(session.state.game!.thrower.name);
        session.submitVisitTotal(score);
      }

      expect(throwers, ['Alice', 'Chloé', 'Bob', 'Dan']);
      expect(session.state.game!.thrower, alice);
      expect(session.state.x01!.scoreOf(ab).remaining, 501 - 160);
      expect(session.state.x01!.scoreOf(cd).remaining, 501 - 71);
    });

    test('a single player throws for themselves', () {
      final session = newSession()..startGame([alice, bob]);
      expect(session.state.game!.thrower, alice);
    });

    test('teams and bots are stored with the game', () {
      final event = GameStarted(
        players: [ab, Player.bot(70)],
        config: const X01Config(),
      );
      final encoded = encodeEvent(event);
      final decoded = decodeEvent(encoded.type, encoded.payload) as GameStarted;

      expect(decoded.players.first.members, [alice, bob]);
      expect(decoded.players.last.botAverage, 70);
      expect(decoded.players.first.isTeam, isTrue);
    });

    test('teams are left out of the stats', () {
      final session = newSession()..startGame([ab, cd]);
      play(session, [60, 60]);
      expect(playerStats([session.state]), isEmpty);
    });
  });
}
