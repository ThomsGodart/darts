import 'package:darts_points_counter/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_test_harness.dart';

void main() {
  testWidgets('empty before anything is played', (tester) async {
    await pumpApp(tester, AppStorage());
    await tester.tap(find.text('Statistiques'));
    await tester.pumpAndSettle();

    expect(find.text('Aucune partie jouée pour l’instant'), findsOneWidget);
  });

  testWidgets('shows each player over ended and open sessions', (tester) async {
    final storage = await AppStorage.withTwoPlayers();
    final players = await InMemoryPlayerCatalog(storage.players).active();
    final repository = InMemorySessionRepository(storage.sessions);
    final ended = await repository.create();
    ended
      ..startGame(players, config: const X01Config(startScore: 101))
      ..submitVisitTotal(101, dartsAtCheckout: 3)
      ..endSession();
    final open = await repository.create();
    open
      ..startGame(players, config: const X01Config(startScore: 101))
      ..submitVisitTotal(101, dartsAtCheckout: 3);

    await pumpApp(tester, storage);
    await tester.tap(find.text('Statistiques'));
    await tester.pumpAndSettle();

    expect(find.text('Joueur 1'), findsOneWidget);
    expect(find.text('Joueur 2'), findsOneWidget);
    expect(find.text('2 (100 %)'), findsOneWidget);
    expect(find.text('Meilleure finition'), findsOneWidget);
    expect(find.text('101'), findsOneWidget);
    expect(find.text('3 fléchettes'), findsOneWidget);
  });
}
