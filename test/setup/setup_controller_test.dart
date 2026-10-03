import 'package:darts_points_counter/setup/setup_controller.dart';
import 'package:darts_points_counter/soiree/soiree.dart';
import 'package:darts_points_counter/soiree_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

Future<SetupController> setupWith(List<String> names) async {
  final catalog = InMemoryPlayerCatalog();
  for (final name in names) {
    await catalog.add(name);
  }
  final setup = SetupController(catalog);
  await setup.load();
  return setup;
}

Player named(SetupController setup, String name) =>
    setup.players.firstWhere((p) => p.name == name);

void main() {
  test('existing players are listed, none picked, 501 double-out', () async {
    final setup = await setupWith(['Bob', 'Ana']);

    expect([for (final p in setup.players) p.name], ['Ana', 'Bob']);
    expect(setup.picked, isEmpty);
    expect(setup.config, const X01Config());
    expect(setup.canStart, isFalse);
  });

  test('players are picked in tap order and can be reordered', () async {
    final setup = await setupWith(['Ana', 'Bob', 'Chloé']);
    setup
      ..toggle(named(setup, 'Chloé'))
      ..toggle(named(setup, 'Ana'))
      ..toggle(named(setup, 'Bob'));
    expect([for (final p in setup.picked) p.name], ['Chloé', 'Ana', 'Bob']);

    setup.reorder(2, 0);
    expect([for (final p in setup.picked) p.name], ['Bob', 'Chloé', 'Ana']);

    setup.toggle(named(setup, 'Chloé'));
    expect([for (final p in setup.picked) p.name], ['Bob', 'Ana']);
    expect(setup.canStart, isTrue);
  });

  test('at most $maxPlayers players can be picked', () async {
    final setup = await setupWith([for (var i = 1; i <= 9; i++) 'P$i']);
    for (final player in setup.players) {
      setup.toggle(player);
    }
    expect(setup.picked, hasLength(maxPlayers));
    expect(setup.canPick(setup.players.last), isFalse);
  });

  test('a player added inline is picked straight away', () async {
    final setup = await setupWith(['Ana']);
    expect(await setup.addPlayer(' Bob '), isNull);

    expect([for (final p in setup.players) p.name], ['Ana', 'Bob']);
    expect([for (final p in setup.picked) p.name], ['Bob']);
  });

  test('a refused name is reported and nothing is added', () async {
    final setup = await setupWith(['Ana']);
    expect(await setup.addPlayer('ana'), PlayerNameProblem.taken);
    expect(await setup.addPlayer(' '), PlayerNameProblem.empty);
    expect(setup.players, hasLength(1));
  });

  test('renaming a picked player keeps them picked', () async {
    final setup = await setupWith(['Anna']);
    setup.toggle(named(setup, 'Anna'));

    expect(await setup.renamePlayer(named(setup, 'Anna'), 'Ana'), isNull);
    expect([for (final p in setup.picked) p.name], ['Ana']);
  });

  test('removing a player unpicks them', () async {
    final setup = await setupWith(['Ana', 'Bob']);
    setup.toggle(named(setup, 'Ana'));

    await setup.removePlayer(named(setup, 'Ana'));
    expect([for (final p in setup.players) p.name], ['Bob']);
    expect(setup.picked, isEmpty);
  });

  test('301 and straight-out can be chosen', () async {
    final setup = await setupWith(['Ana']);
    setup
      ..startScore = 301
      ..doubleOut = false;
    expect(
      setup.config,
      const X01Config(startScore: 301, outRule: OutRule.straight),
    );
  });

  test(
    'the result carries the picked players in order and the config',
    () async {
      final setup = await setupWith(['Ana', 'Bob']);
      setup
        ..toggle(named(setup, 'Bob'))
        ..toggle(named(setup, 'Ana'))
        ..startScore = 301;

      final result = setup.result;
      expect([for (final p in result.players) p.name], ['Bob', 'Ana']);
      expect(result.config.startScore, 301);
    },
  );

  test('a player whose game was refused is not marked as played', () async {
    final catalog = InMemoryPlayerCatalog();
    final ana = await catalog.add('Ana');
    final launcher = SoireeLauncher(InMemorySoireeRepository(), catalog);

    await expectLater(
      launcher.newGame((players: [ana, ana], config: const X01Config())),
      throwsStateError,
    );

    await catalog.remove(ana);
    expect(await catalog.archived(), isEmpty, reason: 'deleted, not archived');
  });
}
