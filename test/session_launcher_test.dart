import 'package:darts_points_counter/session/session.dart';
import 'package:darts_points_counter/session_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a refused setup leaves the open session to be resumed', () async {
    final catalog = InMemoryPlayerCatalog();
    final ana = await catalog.add('Ana');
    final launcher = SessionLauncher(InMemorySessionRepository(), catalog);
    final open = await launcher.newGame((
      players: [ana],
      config: const X01Config(),
    ));
    open.submitVisitTotal(60);

    await expectLater(
      launcher.newGame((players: [ana, ana], config: const X01Config())),
      throwsStateError,
    );

    final resumed = await launcher.resume();
    expect(resumed, isNotNull);
    expect(resumed!.state.isEnded, isFalse);
    expect(resumed.state.games, hasLength(1));
  });

  test('nothing was played yet: no last setup', () async {
    final launcher = SessionLauncher(
      InMemorySessionRepository(),
      InMemoryPlayerCatalog(),
    );
    expect(await launcher.lastSetup(), isNull);
  });

  test(
    'the last setup is the latest game, in the order it was thrown',
    () async {
      final catalog = InMemoryPlayerCatalog();
      final ana = await catalog.add('Ana');
      final bob = await catalog.add('Bob');
      final launcher = SessionLauncher(InMemorySessionRepository(), catalog);
      final session = await launcher.newGame((
        players: [ana],
        config: const X01Config(startScore: 301),
      ));
      session.submitVisitTotal(60);
      const cricket = CricketConfig(variant: CricketVariant.cutThroat);
      await launcher.newGame((players: [bob, ana], config: cricket));

      final last = await launcher.lastSetup();
      expect(last!.players, [bob, ana]);
      expect(last.config, cricket);
    },
  );
}
