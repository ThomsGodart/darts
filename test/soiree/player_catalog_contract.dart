import 'dart:async';

import 'package:darts_points_counter/soiree/soiree.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens a catalog on storage that outlives it; opening a second one
/// simulates relaunching the app.
typedef OpenCatalog = PlayerCatalog Function();

/// Behaviour every [PlayerCatalog] must have, whatever its storage.
void playerCatalogContract(
  String name,
  FutureOr<OpenCatalog> Function() newStorage,
) {
  group('$name player catalog', () {
    late OpenCatalog open;

    setUp(() async => open = await newStorage());

    test('starts empty', () async {
      expect(await open().active(), isEmpty);
    });

    test('a player needs only a name, trimmed', () async {
      final catalog = open();
      final ana = await catalog.add('  Ana ');

      expect(ana.name, 'Ana');
      expect(await catalog.active(), [ana]);
    });

    test('players are listed by name and survive a relaunch', () async {
      final catalog = open();
      await catalog.add('zoé');
      await catalog.add('Bob');
      await catalog.add('ana');

      final names = [for (final p in await open().active()) p.name];
      expect(names, ['ana', 'Bob', 'zoé']);
    });

    test('ids are unique', () async {
      final catalog = open();
      final a = await catalog.add('A');
      final b = await catalog.add('B');
      expect(a.id, isNot(b.id));
    });

    test('names must be non-empty and not already taken', () async {
      final catalog = open();
      await catalog.add('Ana');

      expect(await catalog.nameProblem('   '), PlayerNameProblem.empty);
      expect(await catalog.nameProblem('ana'), PlayerNameProblem.taken);
      expect(await catalog.nameProblem('Bob'), isNull);
      await expectLater(catalog.add(''), throwsArgumentError);
      await expectLater(catalog.add(' ANA '), throwsArgumentError);
    });

    test('rename', () async {
      final catalog = open();
      final ana = await catalog.add('Anna');
      await catalog.add('Bob');

      await catalog.rename(ana, 'Ana');
      expect([for (final p in await open().active()) p.name], ['Ana', 'Bob']);
      await expectLater(catalog.rename(ana, 'bob'), throwsArgumentError);
    });

    test('renaming to the same name with another case is allowed', () async {
      final catalog = open();
      final ana = await catalog.add('ana');
      await catalog.rename(ana, 'Ana');
      expect((await catalog.active()).single.name, 'Ana');
    });

    test('a player who never played is deleted for good', () async {
      final catalog = open();
      final ana = await catalog.add('Ana');

      await catalog.remove(ana);

      expect(await open().active(), isEmpty);
      expect(await open().archived(), isEmpty);
    });

    test('a player who played is archived, never deleted', () async {
      final catalog = open();
      final ana = await catalog.add('Ana');
      final bob = await catalog.add('Bob');
      await catalog.markPlayed([ana]);

      await catalog.remove(ana);
      await catalog.remove(bob);

      expect(await open().active(), isEmpty);
      expect([for (final p in await open().archived()) p.name], ['Ana']);
    });

    test('an archived name can be used again', () async {
      final catalog = open();
      final ana = await catalog.add('Ana');
      await catalog.markPlayed([ana]);
      await catalog.remove(ana);

      expect(await catalog.nameProblem('Ana'), isNull);
      final newAna = await catalog.add('Ana');
      expect(newAna.id, isNot(ana.id));
    });

    test('removing a player twice is harmless', () async {
      final catalog = open();
      final ana = await catalog.add('Ana');
      await catalog.remove(ana);
      await catalog.remove(ana);
      expect(await catalog.active(), isEmpty);
    });

    test('two quick adds of one name keep a single player', () async {
      final catalog = open();
      final results = await Future.wait([
        catalog.add('Ana').then<Object>((p) => p, onError: (Object e) => e),
        catalog.add('ana').then<Object>((p) => p, onError: (Object e) => e),
      ]);

      expect(results.whereType<Player>(), hasLength(1));
      expect(results.whereType<ArgumentError>(), hasLength(1));
      expect(await catalog.active(), hasLength(1));
    });
  });
}
