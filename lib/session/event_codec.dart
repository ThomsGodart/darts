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

Map<String, Object?> _encodeConfig(GameConfig config) => {
  'kind': config.kind.name,
  ...switch (config) {
    X01Config(
      :final startScore,
      :final outRule,
      :final legsToWin,
      :final setsToWin,
    ) =>
      {
        'startScore': startScore,
        'outRule': outRule.name,
        'legsToWin': legsToWin,
        'setsToWin': setsToWin,
      },
    CricketConfig(:final variant, :final input) => {
      'variant': variant.name,
      'input': input.name,
    },
    ShanghaiConfig(:final length, :final instantShanghai) => {
      'length': length.name,
      'instantShanghai': instantShanghai,
    },
    KillerConfig(:final lives, :final doublesToKiller) => {
      'lives': lives,
      'doublesToKiller': doublesToKiller,
    },
    HalveItConfig() => const {},
    GolfConfig(:final holes) => {'holes': holes},
    AroundTheClockConfig(:final finishOnBull) => {'finishOnBull': finishOnBull},
    Bobs27Config() => const {},
    CountUpConfig(:final rounds) => {'rounds': rounds},
    BaseballConfig() => const {},
  },
};

/// Journals written before game kinds existed hold X01 games only.
GameConfig _decodeConfig(Map<String, Object?> payload) =>
    switch (_decodeKind(payload['kind'])) {
      GameKind.x01 => X01Config(
        startScore: payload['startScore']! as int,
        outRule: OutRule.values.byName(payload['outRule']! as String),
        // Games recorded before matches existed were single legs.
        legsToWin: payload['legsToWin'] as int? ?? 1,
        setsToWin: payload['setsToWin'] as int? ?? 1,
      ),
      GameKind.cricket => CricketConfig(
        variant: CricketVariant.values.byName(payload['variant']! as String),
        // Games recorded before the choice existed used the keypad.
        input: switch (payload['input']) {
          final String name => CricketInput.values.byName(name),
          _ => CricketInput.keypad,
        },
      ),
      GameKind.shanghai => ShanghaiConfig(
        length: ShanghaiLength.values.byName(payload['length']! as String),
        instantShanghai: payload['instantShanghai']! as bool,
      ),
      GameKind.killer => KillerConfig(
        lives: payload['lives']! as int,
        doublesToKiller: payload['doublesToKiller']! as int,
      ),
      GameKind.halveIt => const HalveItConfig(),
      GameKind.golf => GolfConfig(holes: payload['holes']! as int),
      GameKind.aroundTheClock => AroundTheClockConfig(
        finishOnBull: payload['finishOnBull']! as bool,
      ),
      GameKind.bobs27 => const Bobs27Config(),
      GameKind.countUp => CountUpConfig(rounds: payload['rounds']! as int),
      GameKind.baseball => const BaseballConfig(),
    };

GameKind _decodeKind(Object? stored) => switch (stored) {
  null => GameKind.x01,
  final String name =>
    GameKind.values.asNameMap()[name] ??
        (throw FormatException('Unknown game kind "$name"')),
  _ => throw FormatException('Unknown game kind "$stored"'),
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
