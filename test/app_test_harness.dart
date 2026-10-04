import 'package:darts_points_counter/app.dart';
import 'package:darts_points_counter/session/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Storage that outlives one pumped app, to simulate relaunches.
class AppStorage {
  final sessions = InMemorySessionStorage();
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
Future<void> pumpApp(
  WidgetTester tester,
  AppStorage storage, {
  SessionRepository? repository,
}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    DartsApp(
      repository: repository ?? InMemorySessionRepository(storage.sessions),
      catalog: InMemoryPlayerCatalog(storage.players),
    ),
  );
  await tester.pumpAndSettle();
}

/// From the home screen: a new session with [players], in that order,
/// playing [game] with the setup [options] tapped.
Future<void> launchGame(
  WidgetTester tester, [
  List<String> players = const ['Joueur 1', 'Joueur 2'],
  String? game,
  List<String> options = const [],
]) async {
  await tester.tap(find.text('Nouvelle session'));
  await tester.pumpAndSettle();
  for (final name in players) {
    await tester.tap(find.widgetWithText(CheckboxListTile, name));
    await tester.pump();
  }
  for (final choice in [?game, ...options]) {
    await tapInSetup(tester, choice);
  }
  await tester.tap(find.text('Lancer la partie'));
  await tester.pumpAndSettle();
}

/// Taps [text] on the setup screen, scrolling it clear of the edges
/// first: the rules sit under a list of games that fills the screen.
Future<void> tapInSetup(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await tester.scrollUntilVisible(
    finder,
    100,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}
