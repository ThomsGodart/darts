import 'package:darts_points_counter/session/session.dart';
import 'package:darts_points_counter/setup/setup_controller.dart';
import 'package:flutter_test/flutter_test.dart';

Future<SetupController> setupWith(
  List<String> names, {
  GameSetup Function(List<Player>)? from,
}) async {
  final catalog = InMemoryPlayerCatalog();
  final players = [for (final name in names) await catalog.add(name)];
  final setup = SetupController(catalog, from: from?.call(players));
  await setup.load();
  return setup;
}

void main() {
  group('virtual opponent', () {
    test('a bot is picked like a player, and unpicked the same way', () async {
      final setup = await setupWith(['Ana']);
      setup
        ..toggle(setup.players.single)
        ..toggle(Player.bot(60));

      expect([for (final p in setup.result.players) p.name], ['Ana', 'Bot 60']);
      expect(setup.canStart, isTrue);

      setup.toggle(Player.bot(60));
      expect(setup.picked, hasLength(1));
    });

    test('a bot only plays the games entered as totals', () async {
      final setup = await setupWith(['Ana']);
      setup
        ..toggle(setup.players.single)
        ..toggle(Player.bot(60));

      setup.kind = GameKind.cricket;
      expect(setup.canStart, isFalse);
      expect(setup.problem, SetupProblem.botCannotPlay);
      setup.kind = GameKind.countUp;
      expect(setup.canStart, isTrue);
      expect(setup.problem, isNull);
    });

    test('a prefilled bot survives loading the catalog', () async {
      final setup = await setupWith(
        ['Ana'],
        from: (players) => (
          players: [players.single, Player.bot(40)],
          config: const X01Config(),
        ),
      );
      expect([for (final p in setup.picked) p.name], ['Ana', 'Bot 40']);
    });
  });

  group('teams', () {
    Future<SetupController> allPicked(List<String> names) async {
      final setup = await setupWith(names);
      for (final player in setup.players) {
        setup.toggle(player);
      }
      return setup;
    }

    List<String> sideNames(SetupController setup) => [
      for (final side in setup.result.players) side.name,
    ];

    test('without teams, everyone plays for themselves', () async {
      final setup = await allPicked(['Ana', 'Bob', 'Cléo']);
      expect(setup.teamCount, 0);
      expect(sideNames(setup), ['Ana', 'Bob', 'Cléo']);
    });

    test('asking for teams deals the players out in turn', () async {
      final setup = await allPicked(['Ana', 'Bob', 'Cléo', 'Dan']);
      setup.teamCount = 2;

      expect(sideNames(setup), ['Ana & Cléo', 'Bob & Dan']);
      expect(setup.canStart, isTrue);
    });

    test('teams need not be even: five players, two against three', () async {
      final setup = await allPicked(['Ana', 'Bob', 'Cléo', 'Dan', 'Eve']);
      setup.teamCount = 2;
      expect(sideNames(setup), ['Ana & Cléo & Eve', 'Bob & Dan']);
      expect(setup.canStart, isTrue);
    });

    test('players choose who is with whom', () async {
      final setup = await allPicked(['Ana', 'Bob', 'Cléo', 'Dan', 'Eve']);
      setup.teamCount = 2;
      final byName = {for (final p in setup.players) p.name: p};
      setup
        ..assign(byName['Bob']!, 0)
        ..assign(byName['Cléo']!, 1)
        ..assign(byName['Eve']!, 1);

      expect(setup.teamOf(byName['Bob']!), 0);
      expect(sideNames(setup), ['Ana & Bob', 'Cléo & Dan & Eve']);
    });

    test('three teams, and a player alone is no team', () async {
      final setup = await allPicked(['Ana', 'Bob', 'Cléo', 'Dan']);
      setup.teamCount = 3;

      expect(sideNames(setup), ['Ana & Dan', 'Bob', 'Cléo']);
      expect(setup.result.players[1].isTeam, isFalse);
    });

    test('a team left without anyone keeps the game from starting', () async {
      final setup = await allPicked(['Ana', 'Bob', 'Cléo']);
      setup.teamCount = 2;
      setup.assign(setup.players[1], 0);

      expect(setup.problem, SetupProblem.emptyTeam);
      expect(setup.canStart, isFalse);
    });

    test('a player picked later joins the smallest team', () async {
      final setup = await setupWith(['Ana', 'Bob', 'Cléo']);
      setup
        ..toggle(setup.players[0])
        ..toggle(setup.players[1])
        ..teamCount = 2
        ..assign(setup.players[1], 0)
        ..toggle(setup.players[2]);

      expect(sideNames(setup), ['Ana & Bob', 'Cléo']);
    });

    test('a bot can be anyone’s team mate', () async {
      final setup = await allPicked(['Ana', 'Bob']);
      setup
        ..toggle(Player.bot(60))
        ..toggle(Player.bot(40))
        ..teamCount = 2;

      // Dealt out in turn: each person with a bot.
      expect(sideNames(setup), ['Ana & Bot 60', 'Bob & Bot 40']);
      expect(setup.problem, isNull);
      expect(setup.canStart, isTrue);
    });

    test('a team with a bot still needs a game bots can play', () async {
      final setup = await allPicked(['Ana', 'Bob']);
      setup
        ..toggle(Player.bot(60))
        ..toggle(Player.bot(40))
        ..teamCount = 2
        ..kind = GameKind.cricket;
      expect(setup.problem, SetupProblem.botCannotPlay);
    });

    test('a setup prefilled with teams opens on the same teams', () async {
      final setup = await setupWith(
        ['Ana', 'Bob', 'Cléo', 'Dan', 'Eve'],
        from: (p) => (
          players: [
            Player.team([p[2], p[0], p[4]]),
            Player.team([p[1], p[3]]),
          ],
          config: const X01Config(),
        ),
      );

      expect(setup.teamCount, 2);
      expect(sideNames(setup), ['Cléo & Ana & Eve', 'Bob & Dan']);
    });
  });
}
