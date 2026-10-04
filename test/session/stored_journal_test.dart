import 'package:darts_points_counter/session/event_codec.dart';
import 'package:darts_points_counter/session/fold.dart';
import 'package:darts_points_counter/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

/// What is on players' phones. These literals are the storage format:
/// if a test here fails, a stored journal no longer replays as it was
/// played. Fix the code or write a migration — do not edit the literals.
void main() {
  test('stored event types', () {
    expect(
      [
        EventTypes.gameStarted,
        EventTypes.visitTotalSubmitted,
        EventTypes.dartThrown,
        EventTypes.visitEnded,
        EventTypes.numberAssigned,
        EventTypes.sessionEnded,
      ],
      [
        'game_started',
        'visit_total_submitted',
        'dart_thrown',
        'visit_ended',
        'number_assigned',
        'session_ended',
      ],
    );
  });

  test('stored game kinds', () {
    expect(
      [for (final kind in GameKind.values) kind.name],
      ['x01', 'cricket', 'shanghai', 'killer', 'halveIt', 'golf'],
    );
  });

  test('a journal as stored, oldest shapes included, replays as played', () {
    const ana = {'id': 'a', 'name': 'Ana'};
    const bob = {'id': 'b', 'name': 'Bob'};
    const cleo = {'id': 'c', 'name': 'Cléo'};
    Map<String, Object?> dart(int sector, int multiplier) => {
      'sector': sector,
      'multiplier': multiplier,
    };
    final stored = <(String, Map<String, Object?>)>[
      // Before game kinds existed: an X01 game without a "kind".
      (
        'game_started',
        {
          'players': [ana, bob],
          'startScore': 101,
          'outRule': 'double',
        },
      ),
      ('visit_total_submitted', {'score': 60, 'darts': 3}),
      ('dart_thrown', dart(20, 1)),
      ('visit_ended', {}),
      ('visit_total_submitted', {'score': 41, 'darts': 2}),
      // Before the input choice existed: a cricket game without "input".
      (
        'game_started',
        {
          'players': [ana, bob],
          'kind': 'cricket',
          'variant': 'standard',
        },
      ),
      ('dart_thrown', dart(20, 3)),
      ('dart_thrown', dart(20, 3)),
      ('visit_ended', {}),
      (
        'game_started',
        {
          'players': [ana, bob],
          'kind': 'shanghai',
          'length': 'oneToSeven',
          'instantShanghai': true,
        },
      ),
      ('dart_thrown', dart(1, 1)),
      ('dart_thrown', dart(1, 2)),
      ('dart_thrown', dart(1, 3)),
      (
        'game_started',
        {
          'players': [ana, bob, cleo],
          'kind': 'killer',
          'lives': 3,
          'doublesToKiller': 1,
        },
      ),
      ('number_assigned', {'sector': 1}),
      ('number_assigned', {'sector': 2}),
      ('number_assigned', {'sector': 3}),
      ('dart_thrown', dart(1, 2)),
      ('session_ended', {}),
    ];

    final state = foldEvents([
      for (final (type, payload) in stored) decodeEvent(type, payload),
    ]);

    expect(state.isEnded, isTrue);
    expect(state.games, hasLength(4));

    final x01 = state.games[0] as X01Game;
    expect(x01.config, const X01Config(startScore: 101));
    expect(x01.winner?.name, 'Ana');
    expect(x01.scores[0].dartsThrown, 5);
    expect(x01.scores[1].remaining, 81);
    expect(x01.scores[1].lastVisit!.darts, dartsPerVisit);

    final cricket = state.games[1] as CricketGame;
    expect(cricket.config, const CricketConfig(input: CricketInput.keypad));
    expect(cricket.scores[0].points, 60);
    expect(cricket.scores[0].isClosed(20), isTrue);
    expect(cricket.activePlayer.name, 'Bob');

    final shanghai = state.games[2] as ShanghaiGame;
    expect(shanghai.winner?.name, 'Ana');
    expect(shanghai.scores[0].points, 6);

    final killer = state.games[3] as KillerGame;
    expect(killer.phase, KillerPhase.playing);
    expect(killer.scores[0].isKiller, isTrue);
    expect([for (final s in killer.scores) s.number], [1, 2, 3]);
    expect(killer.dartsInVisit, hasLength(1));
  });
}
