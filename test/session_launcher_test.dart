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
}
