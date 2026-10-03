import 'package:darts_points_counter/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const killer = KillerConfig();
const carol = Player(id: 'carol', name: 'Carol');

KillerGame killerOf(Session session) => session.state.game! as KillerGame;

const miss = Dart.miss;

void visit(Session session, [List<Dart> darts = const []]) {
  final padded = [...darts, for (var i = darts.length; i < 3; i++) miss];
  for (final dart in padded) {
    if (session.state.game!.isFinished) return;
    expect(session.throwDart(dart), isA<Accepted>(), reason: '$dart');
  }
}

void assignAll(Session session, List<int> numbers) {
  for (final n in numbers) {
    expect(session.assignNumber(n), isA<Accepted>(), reason: 'D$n');
  }
}

void main() {
  test('needs at least three players', () {
    final session = newSession();
    expect(session.startGame([alice, bob], config: killer), isA<Rejected>());
  });

  test('starts in assigning with full lives', () {
    final session = newSession()
      ..startGame([alice, bob, carol], config: killer);
    final game = killerOf(session);
    expect(game.phase, KillerPhase.assigning);
    expect(game.scoreOf(alice).lives, 3);
    expect(game.scoreOf(alice).number, isNull);
  });

  test('assigns unique numbers then starts playing', () {
    final session = newSession()
      ..startGame([alice, bob, carol], config: killer);
    assignAll(session, [20, 19, 18]);
    final game = killerOf(session);
    expect(game.phase, KillerPhase.playing);
    expect(game.scoreOf(alice).number, 20);
    expect(game.scoreOf(bob).number, 19);
    expect(game.scoreOf(carol).number, 18);
    expect(game.activePlayer, alice);
  });

  test('refuses a duplicate number', () {
    final session = newSession()
      ..startGame([alice, bob, carol], config: killer);
    expect(session.assignNumber(20), isA<Accepted>());
    expect(session.assignNumber(20), isA<Rejected>());
  });

  test('own double makes a Killer when N is 1', () {
    final session = newSession()
      ..startGame([alice, bob, carol], config: killer);
    assignAll(session, [20, 19, 18]);
    visit(session, [const Dart.double(20)]);
    expect(killerOf(session).scoreOf(alice).isKiller, isTrue);
  });

  test('a Killer removes a life on an opponent double', () {
    final session = newSession()
      ..startGame([alice, bob, carol], config: killer);
    assignAll(session, [20, 19, 18]);
    visit(session, [const Dart.double(20)]); // alice killer
    visit(session); // bob
    visit(session); // carol
    visit(session, [const Dart.double(19)]); // alice hits bob
    expect(killerOf(session).scoreOf(bob).lives, 2);
  });

  test('a Killer loses a life on their own double', () {
    final session = newSession()
      ..startGame([alice, bob, carol], config: killer);
    assignAll(session, [20, 19, 18]);
    visit(session, [const Dart.double(20)]);
    visit(session);
    visit(session);
    visit(session, [const Dart.double(20)]);
    expect(killerOf(session).scoreOf(alice).lives, 2);
  });

  test('last standing wins after lives are gone', () {
    final session = newSession()
      ..startGame([alice, bob, carol], config: killer);
    assignAll(session, [20, 19, 18]);
    visit(session, [const Dart.double(20)]); // alice killer
    // Three rounds: strip one life from bob and carol each time.
    for (var life = 0; life < 3; life++) {
      visit(session); // bob
      if (session.state.game!.isFinished) break;
      visit(session); // carol
      if (session.state.game!.isFinished) break;
      visit(session, [const Dart.double(19), const Dart.double(18)]);
      if (session.state.game!.isFinished) break;
    }
    expect(killerOf(session).winner, alice);
    expect(killerOf(session).isFinished, isTrue);
  });

  test('OUT players are skipped on the next turn', () {
    final session = newSession()
      ..startGame([alice, bob, carol], config: killer);
    assignAll(session, [20, 19, 18]);
    visit(session, [const Dart.double(20)]); // alice killer
    // Strip bob's three lives in one visit each round.
    for (var i = 0; i < 3; i++) {
      visit(session); // bob
      visit(session); // carol
      visit(session, [const Dart.double(19)]);
    }
    expect(killerOf(session).scoreOf(bob).isOut, isTrue);
    expect(killerOf(session).activePlayer, carol);
  });

  test('undo takes back an assignment', () {
    final session = newSession()
      ..startGame([alice, bob, carol], config: killer);
    session.assignNumber(20);
    expect(session.undo(), isA<Accepted>());
    expect(killerOf(session).scoreOf(alice).number, isNull);
    expect(killerOf(session).activePlayer, alice);
  });

  test('rematch after a win re-enters assigning with rotated order', () {
    final session = newSession()
      ..startGame([
        alice,
        bob,
        carol,
      ], config: const KillerConfig(lives: 5, doublesToKiller: 1));
    assignAll(session, [20, 19, 18]);
    visit(session, [const Dart.double(20)]);
    for (var life = 0; life < 5; life++) {
      visit(session);
      if (session.state.game!.isFinished) break;
      visit(session);
      if (session.state.game!.isFinished) break;
      visit(session, [const Dart.double(19), const Dart.double(18)]);
      if (session.state.game!.isFinished) break;
    }
    expect(session.rematch(), isA<Accepted>());
    final game = killerOf(session);
    expect(game.config.lives, 5);
    expect(game.phase, KillerPhase.assigning);
    expect(game.players.map((p) => p.id).toList(), ['bob', 'carol', 'alice']);
    expect(game.scoreOf(bob).number, isNull);
  });
}
