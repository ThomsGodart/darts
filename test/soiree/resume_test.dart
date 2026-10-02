import 'package:darts_points_counter/soiree/soiree.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';
import 'repository_contract.dart';

void main() {
  test('a facade rebuilt on the same journal shows the same game', () {
    final journal = InMemoryJournal();
    final soiree = Soiree(journal)
      ..startGame([alice, bob], config: const X01Config(startScore: 301));
    play(soiree, [180, 45, 140, 60]);

    expect(scoreboardOf(Soiree(journal)), scoreboardOf(soiree));
  });

  repositoryContract('in-memory', () {
    final storage = InMemorySoireeStorage();
    return () => InMemorySoireeRepository(storage);
  });
}
