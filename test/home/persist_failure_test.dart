import 'package:darts_points_counter/session/session.dart';
import 'package:darts_points_counter/session_launcher.dart';
import 'package:darts_points_counter/ui/persist_failure_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_test_harness.dart';

void main() {
  testWidgets('a persist failure shows a banner on the home screen', (
    tester,
  ) async {
    final storage = await AppStorage.withTwoPlayers();
    final repository = InMemorySessionRepository(storage.sessions);
    await pumpApp(tester, storage, repository: repository);

    expect(find.byKey(const Key('persist-failure-banner')), findsNothing);

    repository.simulatePersistFailure();
    await tester.pump();

    expect(find.byKey(const Key('persist-failure-banner')), findsOneWidget);
    expect(find.text(PersistFailureBanner.message), findsOneWidget);
  });

  testWidgets('a persist failure shows a banner during a game', (tester) async {
    final storage = await AppStorage.withTwoPlayers();
    final repository = InMemorySessionRepository(storage.sessions);
    await pumpApp(tester, storage, repository: repository);
    await launchGame(tester);

    expect(find.byKey(const Key('persist-failure-banner')), findsNothing);

    repository.simulatePersistFailure();
    await tester.pump();

    expect(find.byKey(const Key('persist-failure-banner')), findsOneWidget);
  });

  test('SessionLauncher forwards persistFailure from the repository', () {
    final repository = InMemorySessionRepository();
    final launcher = SessionLauncher(repository, InMemoryPlayerCatalog());
    var ticks = 0;
    launcher.addListener(() => ticks++);

    expect(launcher.persistFailure, isNull);
    repository.simulatePersistFailure('boom');
    expect(launcher.persistFailure, 'boom');
    expect(ticks, 1);
  });
}
