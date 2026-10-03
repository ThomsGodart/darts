import 'dart.dart';
import 'events.dart';
import 'player.dart';
import 'game_config.dart';

/// Stable type tags stored with each event. Renaming one breaks every
/// stored journal unless a database migration rewrites it too (as the
/// schema v3 migration did for `soiree_ended` → `session_ended`).
abstract final class EventTypes {
  static const gameStarted = 'game_started';
  static const visitTotalSubmitted = 'visit_total_submitted';
  static const dartThrown = 'dart_thrown';
  static const visitEnded = 'visit_ended';
  static const numberAssigned = 'number_assigned';
  static const sessionEnded = 'session_ended';
}

/// Game kinds stored in `game_started`. Never rename one.
abstract final class GameKinds {
  static const x01 = 'x01';
  static const cricket = 'cricket';
  static const shanghai = 'shanghai';
  static const killer = 'killer';
}

Map<String, Object?> _encodeConfig(GameConfig config) => switch (config) {
  X01Config(:final startScore, :final outRule) => {
    'kind': GameKinds.x01,
    'startScore': startScore,
    'outRule': outRule.name,
  },
  CricketConfig(:final variant, :final input) => {
    'kind': GameKinds.cricket,
    'variant': variant.name,
    'input': input.name,
  },
  ShanghaiConfig(:final length, :final instantShanghai) => {
    'kind': GameKinds.shanghai,
    'length': length.name,
    'instantShanghai': instantShanghai,
  },
  KillerConfig(:final lives, :final doublesToKiller) => {
    'kind': GameKinds.killer,
    'lives': lives,
    'doublesToKiller': doublesToKiller,
  },
};

/// Journals written before game kinds existed hold X01 games only.
GameConfig _decodeConfig(Map<String, Object?> payload) =>
    switch (payload['kind'] ?? GameKinds.x01) {
      GameKinds.x01 => X01Config(
        startScore: payload['startScore']! as int,
        outRule: OutRule.values.byName(payload['outRule']! as String),
      ),
      GameKinds.cricket => CricketConfig(
        variant: CricketVariant.values.byName(payload['variant']! as String),
        // Games recorded before the choice existed used the keypad.
        input: switch (payload['input']) {
          final String name => CricketInput.values.byName(name),
          _ => CricketInput.keypad,
        },
      ),
      GameKinds.shanghai => ShanghaiConfig(
        length: ShanghaiLength.values.byName(payload['length']! as String),
        instantShanghai: payload['instantShanghai']! as bool,
      ),
      GameKinds.killer => KillerConfig(
        lives: payload['lives']! as int,
        doublesToKiller: payload['doublesToKiller']! as int,
      ),
      final kind => throw FormatException('Unknown game kind "$kind"'),
    };

/// A storable form of an event: a type tag and a JSON-compatible payload.
typedef EncodedEvent = ({String type, Map<String, Object?> payload});

EncodedEvent encodeEvent(SessionEvent event) => switch (event) {
  GameStarted(:final players, :final config) => (
    type: EventTypes.gameStarted,
    payload: {
      'players': [
        for (final p in players) {'id': p.id, 'name': p.name},
      ],
      ..._encodeConfig(config),
    },
  ),
  VisitTotalSubmitted(:final score, :final darts) => (
    type: EventTypes.visitTotalSubmitted,
    payload: {'score': score, 'darts': darts},
  ),
  DartThrown(:final dart) => (
    type: EventTypes.dartThrown,
    payload: {'sector': dart.sector, 'multiplier': dart.multiplier},
  ),
  VisitEnded() => (type: EventTypes.visitEnded, payload: const {}),
  NumberAssigned(:final sector) => (
    type: EventTypes.numberAssigned,
    payload: {'sector': sector},
  ),
  SessionEnded() => (type: EventTypes.sessionEnded, payload: const {}),
};

SessionEvent decodeEvent(String type, Map<String, Object?> payload) =>
    switch (type) {
      EventTypes.gameStarted => GameStarted(
        players: [
          for (final p in payload['players']! as List)
            Player(id: p['id'] as String, name: p['name'] as String),
        ],
        config: _decodeConfig(payload),
      ),
      EventTypes.visitTotalSubmitted => VisitTotalSubmitted(
        payload['score']! as int,
        darts: payload['darts']! as int,
      ),
      EventTypes.dartThrown => DartThrown(
        Dart.fromStored(
          sector: payload['sector']! as int,
          multiplier: payload['multiplier']! as int,
        ),
      ),
      EventTypes.visitEnded => const VisitEnded(),
      EventTypes.numberAssigned => NumberAssigned(payload['sector']! as int),
      EventTypes.sessionEnded => const SessionEnded(),
      _ => throw FormatException('Unknown event type "$type"'),
    };
