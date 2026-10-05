import 'package:darts_points_counter/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const _x01 = StatsQuery(kind: GameKind.x01);

void main() {
  test('nobody played: no stats', () {
    expect(statsOf(const [], _x01), isEmpty);
  });

  group('X01', () {
    test('average, visits by size, first nine, best finish and best leg', () {
      final session = newSession()..startGame([alice, bob]);
      // Alice: 180, 140, 100, then 81 to finish 501 in 11 darts.
      play(session, [180, 26, 140, 26, 100, 26]);
      checkOut(session, 81, darts: 2);

      final stats = statsFor<X01Stats>(alice, [session]);
      expect(stats.gamesPlayed, 1);
      expect(stats.gamesWon, 1);
      expect(stats.winRate, 1);
      expect(stats.average, closeTo(501 / 11 * 3, 0.001));
      expect(stats.firstNineAverage, closeTo(140, 0.001));
      expect(stats.bestVisit, 180);
      expect(stats.sixtyPlus, 4);
      expect(stats.tons, 3);
      expect(stats.ton40s, 2);
      expect(stats.ton80s, 1);
      expect(stats.bestCheckout, 81);
      expect(stats.fewestDartsToWin, 11);
      expect(stats.dartsPerLegWon, 11);
      expect(stats.dartsThrown, 11);

      final loser = statsFor<X01Stats>(bob, [session]);
      expect(loser.gamesWon, 0);
      expect(loser.bestCheckout, isNull);
      expect(loser.fewestDartsToWin, isNull);
      expect(loser.dartsPerLegWon, isNull);
      expect(loser.average, closeTo(26, 0.001));
    });

    test('a bust is no ton', () {
      final session = newSession()
        ..startGame([alice], config: const X01Config(startScore: 101));
      play(session, [100]); // leaves 1: bust in double-out
      expect(statsFor<X01Stats>(alice, [session]).tons, 0);
    });

    test('stats add up over sessions; the best ones are kept', () {
      final first = newSession()
        ..startGame([alice], config: const X01Config(startScore: 101));
      checkOut(first, 101);
      final second = newSession()
        ..startGame([alice], config: const X01Config(startScore: 40));
      play(second, [0]);
      checkOut(second, 40, darts: 1);

      final stats = statsFor<X01Stats>(alice, [first, second]);
      expect(stats.gamesPlayed, 2);
      expect(stats.gamesWon, 2);
      expect(stats.bestCheckout, 101);
      expect(stats.fewestDartsToWin, 3);
      expect(stats.dartsPerLegWon, 3.5);
      expect(stats.average, closeTo(141 / 7 * 3, 0.001));
    });

    test('a game left unfinished counts its darts, not as a game', () {
      final session = newSession()..startGame([alice, bob]);
      play(session, [60]);

      final stats = statsFor<X01Stats>(alice, [session]);
      expect(stats.gamesPlayed, 0);
      expect(stats.winRate, isNull);
      expect(stats.average, 60);
    });

    test('only the start score asked for', () {
      final session = newSession()
        ..startGame([alice], config: const X01Config(startScore: 101));
      checkOut(session, 101);
      session.startGame([alice], config: const X01Config(startScore: 40));
      checkOut(session, 40, darts: 1);

      final on101 = statsOf(
        gamesOf([session]),
        const StatsQuery(kind: GameKind.x01, startScore: 101),
      ).single;
      expect(on101.gamesPlayed, 1);
      expect((on101 as X01Stats).bestCheckout, 101);
    });

    test('a match counts once it is decided, for whoever won it', () {
      const config = X01Config(startScore: 101, legsToWin: 2);
      final session = newSession()..startGame([alice, bob], config: config);
      checkOut(session, 101);
      expect(statsFor<X01Stats>(alice, [session]).matchesPlayed, 0);

      session.rematch();
      play(session, [0]);
      checkOut(session, 101);

      final winner = statsFor<X01Stats>(alice, [session]);
      expect(winner.gamesPlayed, 2);
      expect(winner.matchesPlayed, 1);
      expect(winner.matchesWon, 1);
      expect(statsFor<X01Stats>(bob, [session]).matchesPlayed, 1);
      expect(statsFor<X01Stats>(bob, [session]).matchesWon, 0);
    });
  });

  group('cricket', () {
    const t20 = Dart.treble(20);
    const cricket = StatsQuery(kind: GameKind.cricket);

    test('MPR, rounds by marks and bulls, over the rounds ended', () {
      final session = newSession()
        ..startGame([alice, bob], config: const CricketConfig())
        ..throwDart(t20)
        ..throwDart(t20)
        ..throwDart(t20)
        ..endVisit() // Alice: 9 marks
        ..endVisit() // Bob: nothing
        ..throwDart(Dart.bull)
        ..throwDart(Dart.outerBull)
        ..throwDart(const Dart.single(5))
        ..endVisit(); // Alice: 3 marks, 2 bulls

      final stats = statsOf(gamesOf([session]), cricket).first as CricketStats;
      expect(stats.player, alice);
      expect(stats.marksPerRound, 6);
      expect(stats.roundsPlayed, 2);
      expect(stats.bestRound, 9);
      expect(stats.fiveMarkRounds, 1);
      expect(stats.sevenMarkRounds, 1);
      expect(stats.nineMarkRounds, 1);
      expect(stats.bulls, 2);
      expect(stats.gamesPlayed, 0, reason: 'the game is not over');
      expect(stats.roundsPerGame, isNull);
    });

    test('a finished game counts its rounds and points', () {
      final session = newSession()
        ..startGame([alice, bob], config: const CricketConfig());
      for (final visit in [
        [t20, const Dart.treble(19), const Dart.treble(18)],
        [const Dart.treble(17), const Dart.treble(16), const Dart.treble(15)],
        [Dart.bull, Dart.outerBull],
      ]) {
        for (final dart in visit) {
          session.throwDart(dart);
        }
        if (session.state.game!.isFinished) break;
        session
          ..endVisit()
          ..endVisit();
      }

      final stats = statsFor<CricketStats>(alice, [
        session,
      ], kind: GameKind.cricket);
      expect(stats.gamesWon, 1);
      expect(stats.roundsPerGame, 3);
      expect(stats.fewestRoundsToWin, 3);
      expect(stats.pointsPerGame, 0);
      final loser = statsFor<CricketStats>(bob, [
        session,
      ], kind: GameKind.cricket);
      expect(loser.fewestRoundsToWin, isNull);
      expect(loser.marksPerRound, 0);
    });

    test('standard and cut-throat are told apart', () {
      final session = newSession()
        ..startGame([alice, bob], config: const CricketConfig())
        ..throwDart(t20)
        ..endSession();
      final cutThroat = statsOf(
        gamesOf([session]),
        const StatsQuery(
          kind: GameKind.cricket,
          variant: CricketVariant.cutThroat,
        ),
      );
      expect(cutThroat, isEmpty);
    });
  });

  group('the other games', () {
    test('games, wins, and the score a game ends on', () {
      final session = newSession()
        ..startGame([alice, bob], config: const CountUpConfig(rounds: 8));
      for (var round = 0; round < 8; round++) {
        session
          ..submitVisitTotal(100)
          ..submitVisitTotal(60);
      }

      final winner = statsFor<ScoreStats>(alice, [
        session,
      ], kind: GameKind.countUp);
      expect(winner.gamesWon, 1);
      expect(winner.averageScore, 800);
      expect(winner.bestScore, 800);
      final loser = statsFor<ScoreStats>(bob, [
        session,
      ], kind: GameKind.countUp);
      expect(loser.gamesPlayed, 1);
      expect(loser.gamesWon, 0);
      expect(loser.bestScore, 480);
    });

    test('in Golf the best score is the fewest strokes', () {
      final session = newSession()
        ..startGame([alice], config: const GolfConfig());
      for (var hole = 1; hole <= 9; hole++) {
        session
          ..throwDart(Dart.double(hole))
          ..endVisit();
      }
      session.startGame([alice], config: const GolfConfig());
      for (var hole = 1; hole <= 9; hole++) {
        session.endVisit();
      }

      final stats = statsFor<ScoreStats>(alice, [session], kind: GameKind.golf);
      expect(stats.bestScore, 9);
      expect(stats.averageScore, 27);
    });
  });

  test('only the kind asked for, and only the games since then', () {
    final old = newSession()
      ..startGame([alice], config: const X01Config(startScore: 101));
    checkOut(old, 101);
    final recent = newSession()
      ..startGame([alice], config: const X01Config(startScore: 101));
    checkOut(recent, 101);
    recent.startGame([alice], config: const GolfConfig());

    final games = [
      ...gamesOf([old], at: DateTime(2026, 9)),
      ...gamesOf([recent], at: DateTime(2026, 10, 5)),
    ];
    expect(kindsPlayed(games), [GameKind.x01, GameKind.golf]);
    expect(statsOf(games, _x01).single.gamesPlayed, 2);
    expect(
      statsOf(
        games,
        StatsQuery(kind: GameKind.x01, since: DateTime(2026, 10)),
      ).single.gamesPlayed,
      1,
    );
    expect(
      statsOf(games, StatsQuery(kind: GameKind.x01, since: DateTime(2026, 11))),
      isEmpty,
    );
  });

  test('a renamed player stays one player, under the latest name', () {
    final first = newSession()..startGame([alice], config: const GolfConfig());
    final second = newSession()
      ..startGame([
        const Player(id: 'alice', name: 'Alicia'),
      ], config: const GolfConfig());

    final all = statsOf(
      gamesOf([first, second]),
      const StatsQuery(kind: GameKind.golf),
    );
    expect(all, hasLength(1));
    expect(all.single.player.name, 'Alicia');
  });
}
