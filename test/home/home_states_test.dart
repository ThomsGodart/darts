import 'dart:async';

import 'package:darts_points_counter/app.dart';
import 'package:darts_points_counter/session/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_test_harness.dart';

/// Delays [latest] so Home can paint its resume loading state.
class _SlowResumeRepository extends InMemorySessionRepository {
  final Completer<void> gate = Completer<void>();

  @override
  Future<Session?> latest() async {
    await gate.future;
    return super.latest();
  }
}

class _FailingResumeRepository extends InMemorySessionRepository {
  @override
  Future<Session?> latest() async => throw StateError('disk unavailable');
}

void main() {
  testWidgets('Home shows empty resume state when nothing to resume', (
    tester,
  ) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-resume-empty')), findsOneWidget);
    expect(find.text('Nouvelle session'), findsOneWidget);
    expect(find.text('Reprendre la session'), findsNothing);
  });

  testWidgets('Home shows loading while resume check runs', (tester) async {
    final storage = await AppStorage.withTwoPlayers();
    final repository = _SlowResumeRepository();
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      DartsApp(
        repository: repository,
        catalog: InMemoryPlayerCatalog(storage.players),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('home-resume-loading')), findsOneWidget);

    repository.gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-resume-loading')), findsNothing);
    expect(find.byKey(const Key('home-resume-empty')), findsOneWidget);
  });

  testWidgets('Home shows a structured resume error', (tester) async {
    final storage = await AppStorage.withTwoPlayers();
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      DartsApp(
        repository: _FailingResumeRepository(),
        catalog: InMemoryPlayerCatalog(storage.players),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-resume-error')), findsOneWidget);
    expect(
      find.text('Impossible de vérifier une session en cours.'),
      findsOneWidget,
    );
  });

  testWidgets('Home opens Settings from the gear', (tester) async {
    await pumpApp(tester, await AppStorage.withTwoPlayers());
    await tester.tap(find.byKey(const Key('settings-button')));
    await tester.pumpAndSettle();
    expect(find.text('Réglages'), findsOneWidget);
  });
}
