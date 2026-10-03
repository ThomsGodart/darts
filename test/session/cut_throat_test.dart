import 'package:darts_points_counter/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cricket_test.dart' show closeAll, cricketOf, t20, visit, chloe;
import 'helpers.dart';

const cutThroat = CricketConfig(variant: CricketVariant.cutThroat);

void main() {
  test('extra marks score for each opponent still open, not the thrower', () {
    final session = newSession()
      ..startGame([alice, bob, chloe], config: cutThroat);
    visit(session, [t20]); // Alice closes 20
    visit(session); // Bob
    visit(session, [t20]); // Chloé closes 20
    visit(session, [t20]); // Alice: 60 to whoever is still open on 20

    final game = cricketOf(session);
    expect(game.scoreOf(alice).points, 0);
    expect(game.scoreOf(bob).points, 60);
    expect(game.scoreOf(chloe).points, 0);
  });

  test('a dead number gives nothing to anyone', () {
    final session = newSession()..startGame([alice, bob], config: cutThroat);
    visit(session, [t20]);
    visit(session, [t20]);
    visit(session, [t20]);
    final game = cricketOf(session);
    expect(game.scoreOf(alice).points, 0);
    expect(game.scoreOf(bob).points, 0);
  });

  test('closing everything with the fewest points wins, ties included', () {
    final session = newSession()..startGame([alice, bob], config: cutThroat);
    closeAll(session, 1);
    expect(cricketOf(session).winner, alice);
  });

  test('closing everything with more points than someone does not win', () {
    final session = newSession()..startGame([alice, bob], config: cutThroat);
    visit(session); // Alice
    visit(session, [t20, t20]); // Bob gives Alice 60 on 20
    closeAll(session, 1); // Alice closes all but has 60 against Bob's 0

    final game = cricketOf(session);
    expect(game.scoreOf(alice).hasClosedAll, isTrue);
    expect(game.scoreOf(alice).points, 60);
    expect(game.winner, isNull);

    // Alice hands Bob 76 on the 19 he has left open, and wins.
    visit(session, [const Dart.treble(19), const Dart.single(19)]);
    expect(cricketOf(session).scoreOf(bob).points, 76);
    expect(cricketOf(session).winner, alice);
  });

  test('Rejouer keeps cut-throat; it survives a relaunch', () async {
    final storage = InMemorySessionStorage();
    final session = await InMemorySessionRepository(storage).create();
    session.startGame([alice, bob], config: cutThroat);
    closeAll(session, 1);
    session.rematch();
    expect(cricketOf(session).config, cutThroat);

    final resumed = await InMemorySessionRepository(storage).resumable();
    expect((resumed!.state.game! as CricketGame).config, cutThroat);
  });

  test('closed out, then left lowest by others: wins on the next dart', () {
    final session = newSession()
      ..startGame([alice, bob, chloe], config: cutThroat);
    visit(session); // Alice
    visit(session, [t20, t20]); // Bob gives Alice and Chloé 60 each
    visit(session); // Chloé
    closeAll(session, 2); // Alice closes all on 60; Bob still on 0

    expect(cricketOf(session).winner, isNull, reason: 'Bob has fewer');
    visit(session); // Alice
    visit(session); // Bob
    // Chloé closes 19 and hands Bob 2 × 57: Alice is now the lowest.
    visit(session, [
      const Dart.treble(19),
      const Dart.treble(19),
      const Dart.treble(19),
    ]);
    expect(cricketOf(session).scoreOf(bob).points, 114);
    expect(cricketOf(session).winner, isNull);

    session.throwDart(Dart.miss);
    expect(cricketOf(session).winner, alice);
  });
}
