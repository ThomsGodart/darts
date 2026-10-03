import 'package:darts_points_counter/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';
import 'repository_contract.dart';

void main() {
  test('a facade rebuilt on the same journal shows the same game', () {
    final journal = InMemoryJournal();
    final session = Session(journal)
      ..startGame([alice, bob], config: const X01Config(startScore: 301));
    play(session, [180, 45, 140, 60]);

    expect(scoreboardOf(Session(journal)), scoreboardOf(session));
  });

  repositoryContract('in-memory', () {
    final storage = InMemorySessionStorage();
    return () => InMemorySessionRepository(storage);
  });
}
