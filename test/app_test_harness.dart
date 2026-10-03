import 'package:darts_points_counter/app.dart';
import 'package:darts_points_counter/soiree/soiree.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Storage that outlives one pumped app, to simulate relaunches.
class AppStorage {
  final soirees = InMemorySoireeStorage();
  final players = InMemoryPlayerStorage();

  /// A catalog already holding "Joueur 1" and "Joueur 2".
  static Future<AppStorage> withTwoPlayers() async {
    final storage = AppStorage();
    final catalog = InMemoryPlayerCatalog(storage.players);
    await catalog.add('Joueur 1');
    await catalog.add('Joueur 2');
    return storage;
  }
}

/// Pumps the app at phone size on [storage].
Future<void> pumpApp(WidgetTester tester, AppStorage storage) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    DartsApp(
      repository: InMemorySoireeRepository(storage.soirees),
      catalog: InMemoryPlayerCatalog(storage.players),
    ),
  );
  await tester.pumpAndSettle();
}

/// From the home screen: a new soirée with [players], in that order.
Future<void> launchGame(
  WidgetTester tester, [
  List<String> players = const ['Joueur 1', 'Joueur 2'],
]) async {
  await tester.tap(find.text('Nouvelle soirée'));
  await tester.pumpAndSettle();
  for (final name in players) {
    await tester.tap(find.widgetWithText(CheckboxListTile, name));
    await tester.pump();
  }
  await tester.tap(find.text('Lancer la partie'));
  await tester.pumpAndSettle();
}
