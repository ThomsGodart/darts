import 'package:darts_points_counter/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const shanghai = ShanghaiConfig();

ShanghaiGame shanghaiOf(Session session) => session.state.game! as ShanghaiGame;

const miss = Dart.miss;

/// One visit: [darts], padded with misses to three.
void visit(Session session, [List<Dart> darts = const []]) {
  final padded = [...darts, for (var i = darts.length; i < 3; i++) miss];
  for (final dart in padded) {
    if (session.state.game!.isFinished) return;
    expect(session.throwDart(dart), isA<Accepted>(), reason: '$dart');
  }
}

void main() {
  test('a new game starts on the first number with zero scores', () {
    final session = newSession()..startGame([alice, bob], config: shanghai);
    final game = shanghaiOf(session);

    expect(game.currentNumber, 1);
    expect(game.scoreOf(alice), 0);
    expect(game.scoreOf(bob), 0);
    expect(game.activePlayer, alice);
  });

  test('only the current number scores; others are zero', () {
    final session = newSession()..startGame([alice, bob], config: shanghai);
    visit(session, [const Dart.treble(1), const Dart.single(20), miss]);

    expect(shanghaiOf(session).scoreOf(alice), 3);
    expect(shanghaiOf(session).activePlayer, bob);
    expect(shanghaiOf(session).currentNumber, 1);
  });

  test('after everyone throws on a number, the sequence advances', () {
    final session = newSession()..startGame([alice, bob], config: shanghai);
    visit(session, [const Dart.single(1)]);
    visit(session, [const Dart.single(1)]);

    expect(shanghaiOf(session).currentNumber, 2);
    expect(shanghaiOf(session).activePlayer, alice);
  });

  test('S+D+T on the number wins at once when instant shanghai is on', () {
    final session = newSession()..startGame([alice, bob], config: shanghai);
    visit(session, [
      const Dart.single(1),
      const Dart.double(1),
      const Dart.treble(1),
    ]);

    expect(shanghaiOf(session).winner, alice);
    expect(shanghaiOf(session).scoreOf(alice), 1 + 2 + 3);
  });

  test('instant shanghai can be turned off', () {
    final session = newSession()
      ..startGame([
        alice,
        bob,
      ], config: const ShanghaiConfig(instantShanghai: false));
    visit(session, [
      const Dart.single(1),
      const Dart.double(1),
      const Dart.treble(1),
    ]);

    expect(shanghaiOf(session).isFinished, isFalse);
    expect(shanghaiOf(session).scoreOf(alice), 6);
    expect(shanghaiOf(session).activePlayer, bob);
  });

  test('highest score wins when the sequence ends', () {
    final session = newSession()
      ..startGame([
        alice,
        bob,
      ], config: const ShanghaiConfig(length: ShanghaiLength.oneToSeven));
    // Alice scores 3 on each of 1–7; Bob scores 0.
    for (var n = 1; n <= 7; n++) {
      visit(session, [Dart.single(n)]);
      if (session.state.game!.isFinished) break;
      visit(session);
    }

    expect(shanghaiOf(session).winner, alice);
    expect(shanghaiOf(session).scoreOf(alice), 1 + 2 + 3 + 4 + 5 + 6 + 7);
  });

  test('14–20 length starts on 14', () {
    final session = newSession()
      ..startGame([
        alice,
      ], config: const ShanghaiConfig(length: ShanghaiLength.fourteenToTwenty));
    expect(shanghaiOf(session).currentNumber, 14);
  });

  test('undo takes back a dart', () {
    final session = newSession()..startGame([alice, bob], config: shanghai);
    session.throwDart(const Dart.treble(1));
    expect(session.undo(), isA<Accepted>());
    expect(shanghaiOf(session).dartsInVisit, isEmpty);
    expect(shanghaiOf(session).scoreOf(alice), 0);
  });

  test('rematch keeps options and rotates the first player', () {
    final session = newSession()
      ..startGame([
        alice,
        bob,
      ], config: const ShanghaiConfig(instantShanghai: false));
    for (var n = 1; n <= 7; n++) {
      visit(session, [Dart.single(n)]);
      if (!session.state.game!.isFinished) visit(session);
    }
    expect(session.rematch(), isA<Accepted>());
    final game = shanghaiOf(session);
    expect(game.config.instantShanghai, isFalse);
    expect(game.activePlayer, bob);
    expect(game.currentNumber, 1);
  });
}
