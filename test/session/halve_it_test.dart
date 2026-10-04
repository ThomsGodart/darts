import 'package:darts_points_counter/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const halveIt = HalveItConfig();
const miss = Dart.miss;

HalveItGame halveItOf(Session session) => session.state.game! as HalveItGame;

/// One visit: [darts], padded with misses to three.
void visit(Session session, [List<Dart> darts = const []]) {
  final padded = [...darts, for (var i = darts.length; i < 3; i++) miss];
  for (final dart in padded) {
    if (session.state.game!.isFinished) return;
    expect(session.throwDart(dart), isA<Accepted>(), reason: '$dart');
  }
}

void main() {
  test('a new game: everyone on the start score, aiming at 20', () {
    final session = newSession()..startGame([alice, bob], config: halveIt);
    final game = halveItOf(session);

    expect(game.currentTarget.label, '20');
    expect(game.scoreOf(alice).points, halveItStartScore);
    expect(game.scoreOf(bob).points, halveItStartScore);
    expect(game.activePlayer, alice);
  });

  test('the targets are 20, 16, D7, 14, T10, 17 and the bull', () {
    expect(
      [for (final target in halveItTargets) target.label],
      ['20', '16', 'D7', '14', 'T10', '17', 'Bull'],
    );
  });

  test('darts on the target add up, whatever their ring', () {
    final session = newSession()..startGame([alice, bob], config: halveIt);
    visit(session, [const Dart.single(20), const Dart.treble(20)]);

    expect(halveItOf(session).scoreOf(alice).points, halveItStartScore + 80);
    expect(halveItOf(session).scoreOf(alice).wasHalved, isFalse);
    expect(halveItOf(session).activePlayer, bob);
  });

  test('darts elsewhere score nothing', () {
    final session = newSession()..startGame([alice, bob], config: halveIt);
    visit(session, [const Dart.treble(19), const Dart.single(20)]);

    expect(halveItOf(session).scoreOf(alice).points, halveItStartScore + 20);
  });

  test('a visit without a hit halves the score, rounding up', () {
    final session = newSession()..startGame([alice], config: halveIt);
    final seen = <int>[];
    for (var i = 0; i < 4; i++) {
      visit(session);
      seen.add(halveItOf(session).scoreOf(alice).points);
    }

    expect(seen, [20, 10, 5, 3]);
    expect(halveItOf(session).scoreOf(alice).wasHalved, isTrue);
  });

  test('the score shown during a visit counts its darts already', () {
    final session = newSession()..startGame([alice, bob], config: halveIt);
    session.throwDart(const Dart.double(20));

    expect(halveItOf(session).activeLivePoints, halveItStartScore + 40);
    expect(halveItOf(session).scoreOf(alice).points, halveItStartScore);
  });

  test('everyone throws at a target before the next one', () {
    final session = newSession()..startGame([alice, bob], config: halveIt);
    visit(session, [const Dart.single(20)]);
    expect(halveItOf(session).currentTarget.label, '20');
    visit(session, [const Dart.single(20)]);
    expect(halveItOf(session).currentTarget.label, '16');
    expect(halveItOf(session).activePlayer, alice);
  });

  test('on D7 and T10 only that ring counts', () {
    final session = newSession()..startGame([alice], config: halveIt);
    visit(session, [const Dart.single(20)]); // 60
    visit(session, [const Dart.single(16)]); // 76
    expect(halveItOf(session).currentTarget.label, 'D7');
    visit(session, [const Dart.single(7), const Dart.treble(7)]); // halved
    expect(halveItOf(session).scoreOf(alice).points, 38);

    visit(session, [const Dart.single(14)]); // 52
    expect(halveItOf(session).currentTarget.label, 'T10');
    visit(session, [const Dart.treble(10), const Dart.double(10)]); // +30
    expect(halveItOf(session).scoreOf(alice).points, 82);
  });

  test('both bulls count on the last target; the highest score wins', () {
    final session = newSession()..startGame([alice, bob], config: halveIt);
    for (var round = 0; round < halveItTargets.length - 1; round++) {
      visit(session);
      visit(session);
    }
    expect(halveItOf(session).currentTarget.label, 'Bull');
    visit(session, [Dart.outerBull, Dart.bull]);
    expect(halveItOf(session).isFinished, isFalse);
    visit(session, [Dart.outerBull]);

    final game = halveItOf(session);
    expect(game.scoreOf(alice).points, 1 + 75);
    expect(game.scoreOf(bob).points, 1 + 25);
    expect(game.winner, alice);
  });

  test('a tie goes to whoever threw first', () {
    final session = newSession()..startGame([alice, bob], config: halveIt);
    for (var round = 0; round < halveItTargets.length; round++) {
      visit(session);
      visit(session);
    }
    expect(halveItOf(session).winner, alice);
  });

  test('undo takes a dart back, even the one that halved', () {
    final session = newSession()..startGame([alice, bob], config: halveIt);
    session
      ..throwDart(miss)
      ..throwDart(miss);
    final before = scoreboardOf(session);
    session.throwDart(miss);
    expect(halveItOf(session).scoreOf(alice).points, 20);

    session.undo();
    expect(scoreboardOf(session), before);
  });
}
