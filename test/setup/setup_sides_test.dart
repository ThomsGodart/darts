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
    test('picked players pair up in order', () async {
      final setup = await setupWith(['Ana', 'Bob', 'Cléo', 'Dan']);
      for (final player in setup.players) {
        setup.toggle(player);
      }
      setup.teams = true;

      expect(
        [for (final side in setup.result.players) side.name],
        ['Ana & Bob', 'Cléo & Dan'],
      );
      expect(setup.canStart, isTrue);
    });

    test('teams need an even number of players, four at least', () async {
      final setup = await setupWith(['Ana', 'Bob', 'Cléo']);
      for (final player in setup.players) {
        setup.toggle(player);
      }
      setup.teams = true;
      expect(setup.canStart, isFalse);
      expect(setup.problem, SetupProblem.teamsNeedPairs);

      setup.toggle(setup.players.last);
      expect(setup.canStart, isFalse);
    });

    test('no bot in a team', () async {
      final setup = await setupWith(['Ana', 'Bob', 'Cléo']);
      for (final player in setup.players) {
        setup.toggle(player);
      }
      setup
        ..toggle(Player.bot(60))
        ..teams = true;
      expect(setup.problem, SetupProblem.botInTeam);
    });

    test('a setup prefilled with teams opens on their members', () async {
      final setup = await setupWith(
        ['Ana', 'Bob', 'Cléo', 'Dan'],
        from: (p) => (
          players: [
            Player.team([p[2], p[0]]),
            Player.team([p[1], p[3]]),
          ],
          config: const X01Config(),
        ),
      );

      expect(setup.teams, isTrue);
      expect(
        [for (final p in setup.picked) p.name],
        ['Cléo', 'Ana', 'Bob', 'Dan'],
      );
    });
  });
}
