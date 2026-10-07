import 'package:darts_points_counter/session/session.dart';
import 'package:darts_points_counter/session_launcher.dart';
import 'package:darts_points_counter/share/session_share.dart';
import 'package:darts_points_counter/share/share_transport.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late InMemoryShareHub hub;
  late SessionLauncher hostLauncher;
  late InMemoryPlayerCatalog hostCatalog;
  late SessionLauncher launcher;
  late InMemoryPlayerCatalog catalog;
  late Player ana;

  /// The host shares a game of [names]; this device joins it.
  Future<SessionShare> joinGameOf(
    List<String> names, {
    bool teams = false,
  }) async {
    final people = [for (final name in names) await hostCatalog.add(name)];
    final session = await hostLauncher.newGame((
      players: teams
          ? [Player.team(people.sublist(0, 2)), ...people.sublist(2)]
          : people,
      config: const X01Config(),
    ));
    final share = hostLauncher.shareOf(session)!;
    await share.start();
    session.submitVisitTotal(60);
    return launcher.join(share.code!);
  }

  setUp(() async {
    hub = InMemoryShareHub();
    hostCatalog = InMemoryPlayerCatalog();
    hostLauncher = SessionLauncher(
      InMemorySessionRepository(),
      hostCatalog,
      shareTransport: hub.transport(),
    );
    catalog = InMemoryPlayerCatalog();
    // This device knows other people, so ids differ from the host's.
    await catalog.add('Zoé');
    ana = await catalog.add('Ana');
    launcher = SessionLauncher(
      InMemorySessionRepository(),
      catalog,
      shareTransport: hub.transport(),
    );
  });

  test('a joined session where nothing was entered is not worth '
      'keeping', () async {
    final people = [await hostCatalog.add('Ana'), await hostCatalog.add('Bob')];
    final session = await hostLauncher.newGame((
      players: people,
      config: const X01Config(),
    ));
    final share = hostLauncher.shareOf(session)!;
    await share.start();
    final guest = await launcher.join(share.code!);

    expect(await launcher.proposeKeeping(guest), isNull);
  });

  test('its people are matched with the known players by name, whatever '
      'the case', () async {
    final guest = await joinGameOf(['ANA', 'Bob']);

    final proposal = (await launcher.proposeKeeping(guest))!;

    expect(proposal.people.map((p) => p.shared.name), ['ANA', 'Bob']);
    expect(proposal.people[0].match, ana);
    expect(proposal.people[1].match, isNull);
    expect(proposal.known.map((p) => p.name), ['Ana', 'Zoé']);
    expect(proposal.endsOpenSession, isFalse);
  });

  test('kept, the session is in the history, ended, with this device\'s '
      'players', () async {
    final guest = await joinGameOf(['Ana', 'Bob']);
    final hostAna = guest.controller.state.game!.players.first;
    expect(hostAna.id, isNot(ana.id));

    await launcher.keep(guest, {hostAna.id: ana});

    final record = (await launcher.history()).single;
    expect(record.state.isEnded, isTrue);
    final players = record.state.game!.players;
    expect(players.first, ana);
    final bob = (await catalog.active()).singleWhere((p) => p.name == 'Bob');
    expect(players.last, bob);
    // The stats count it for this device's Ana.
    final played = await launcher.playedGames();
    expect(played.single.game.players.first.id, ana.id);
    // What was shared is untouched, and still open on the line.
    expect(guest.controller.state.isEnded, isFalse);
    expect(guest.controller.state.game!.players.first, hostAna);
  });

  test('people who played are known players from then on', () async {
    final guest = await joinGameOf(['Ana', 'Bob']);
    await launcher.keep(guest, {
      guest.controller.state.game!.players.first.id: ana,
    });

    // A player who played is archived when removed, not deleted.
    final bob = (await catalog.active()).singleWhere((p) => p.name == 'Bob');
    await catalog.remove(bob);
    expect(await catalog.archived(), [bob]);
  });

  test('someone said to be new although their name is known gets a name '
      'of their own', () async {
    final guest = await joinGameOf(['Ana', 'Bob']);

    await launcher.keep(guest, const {});

    expect(
      (await catalog.active()).map((p) => p.name),
      containsAll(['Ana', 'Ana (2)', 'Bob']),
    );
    final record = (await launcher.history()).single;
    expect(record.state.game!.players.first.name, 'Ana (2)');
  });

  test('the members of a team are told apart too', () async {
    final guest = await joinGameOf(['Ana', 'Bob', 'Cléo'], teams: true);
    final proposal = (await launcher.proposeKeeping(guest))!;
    expect(proposal.people.map((p) => p.shared.name), ['Ana', 'Bob', 'Cléo']);

    await launcher.keep(guest, {proposal.people.first.shared.id: ana});

    final team = (await launcher.history()).single.state.game!.players.first;
    expect(team.isTeam, isTrue);
    expect(team.members.first, ana);
    expect(team.name, 'Ana & Bob');
    expect(team.id, contains(ana.id));
  });

  test('two people cannot be kept as one player: nothing is '
      'written', () async {
    final guest = await joinGameOf(['Ana', 'Bob']);
    final players = guest.controller.state.game!.players;

    await expectLater(
      launcher.keep(guest, {players[0].id: ana, players[1].id: ana}),
      throwsArgumentError,
    );
    expect(await launcher.history(), isEmpty);
  });

  test('a session open on this device is ended first, and stays in the '
      'history', () async {
    final own = await launcher.newGame((
      players: [ana],
      config: const X01Config(),
    ));
    own.submitVisitTotal(26);
    final guest = await joinGameOf(['Ana', 'Bob']);
    expect((await launcher.proposeKeeping(guest))!.endsOpenSession, isTrue);

    await launcher.keep(guest, const {});

    expect(await launcher.canResume(), isFalse);
    expect(await launcher.history(), hasLength(2));
  });

  test('kept again after more was played, a session is in the history '
      'once', () async {
    final guest = await joinGameOf(['Ana', 'Bob']);
    // As the dialog answers when its matches are left as proposed.
    Future<Map<String, Player>> asProposed() async => {
      for (final (:shared, :match) in (await launcher.proposeKeeping(
        guest,
      ))!.people)
        shared.id: ?match,
    };
    await launcher.keep(guest, await asProposed());

    guest.controller.submitVisitTotal(100);
    await _settle();
    await launcher.keep(guest, await asProposed());

    final record = (await launcher.history()).single;
    expect(record.state.game!.visitsPlayed, 2);
    // Bob was made once.
    expect((await catalog.active()).where((p) => p.name.startsWith('Bob')), [
      isA<Player>(),
    ]);
  });
}
