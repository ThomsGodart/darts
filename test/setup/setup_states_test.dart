import 'dart:async';

import 'package:darts_points_counter/setup/setup_controller.dart';
import 'package:darts_points_counter/setup/setup_screen.dart';
import 'package:darts_points_counter/session/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _GatedCatalog implements PlayerCatalog {
  _GatedCatalog(this._inner);

  final PlayerCatalog _inner;
  final Completer<void> gate = Completer<void>();

  @override
  Future<List<Player>> active() async {
    await gate.future;
    return _inner.active();
  }

  @override
  Future<List<Player>> archived() => _inner.archived();

  @override
  Future<PlayerNameProblem?> nameProblem(String name, {Player? renaming}) =>
      _inner.nameProblem(name, renaming: renaming);

  @override
  Future<Player> add(String name) => _inner.add(name);

  @override
  Future<void> rename(Player player, String name) =>
      _inner.rename(player, name);

  @override
  Future<void> remove(Player player) => _inner.remove(player);

  @override
  Future<void> markPlayed(Iterable<Player> players) =>
      _inner.markPlayed(players);
}

class _FailingCatalog implements PlayerCatalog {
  @override
  Future<List<Player>> active() async =>
      throw StateError('catalog unavailable');

  @override
  Future<List<Player>> archived() async => const [];

  @override
  Future<PlayerNameProblem?> nameProblem(String name, {Player? renaming}) async =>
      null;

  @override
  Future<Player> add(String name) async =>
      throw UnsupportedError('add');

  @override
  Future<void> rename(Player player, String name) async {}

  @override
  Future<void> remove(Player player) async {}

  @override
  Future<void> markPlayed(Iterable<Player> players) async {}
}

Future<void> _pumpSetup(WidgetTester tester, SetupController controller) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(home: SetupScreen(controller: controller)),
  );
}

void main() {
  testWidgets('Setup shows loading while the catalog loads', (tester) async {
    final gated = _GatedCatalog(InMemoryPlayerCatalog());
    final setup = SetupController(gated);
    addTearDown(setup.dispose);

    await _pumpSetup(tester, setup);
    await tester.pump();

    expect(find.byKey(const Key('setup-catalog-loading')), findsOneWidget);

    gated.gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('setup-catalog-loading')), findsNothing);
  });

  testWidgets('Setup shows empty catalog copy', (tester) async {
    final setup = SetupController(InMemoryPlayerCatalog());
    addTearDown(setup.dispose);

    await _pumpSetup(tester, setup);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('setup-catalog-empty')), findsOneWidget);
    expect(find.textContaining('Aucun joueur'), findsOneWidget);
  });

  testWidgets('Setup shows a structured catalog error', (tester) async {
    final setup = SetupController(_FailingCatalog());
    addTearDown(setup.dispose);

    await _pumpSetup(tester, setup);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('setup-catalog-error')), findsOneWidget);
    expect(find.text('Impossible de charger les joueurs.'), findsOneWidget);
  });
}
