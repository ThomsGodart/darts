import 'dart.dart';
import 'events.dart';
import 'player.dart';
import 'x01_config.dart';

/// Stable type tags stored with each event. Never rename one: stored
/// journals would no longer replay.
abstract final class EventTypes {
  static const gameStarted = 'game_started';
  static const visitTotalSubmitted = 'visit_total_submitted';
  static const dartThrown = 'dart_thrown';
  static const soireeEnded = 'soiree_ended';
}

/// A storable form of an event: a type tag and a JSON-compatible payload.
typedef EncodedEvent = ({String type, Map<String, Object?> payload});

EncodedEvent encodeEvent(SoireeEvent event) => switch (event) {
  GameStarted(:final players, :final config) => (
    type: EventTypes.gameStarted,
    payload: {
      'players': [
        for (final p in players) {'id': p.id, 'name': p.name},
      ],
      'startScore': config.startScore,
      'outRule': config.outRule.name,
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
  SoireeEnded() => (type: EventTypes.soireeEnded, payload: const {}),
};

SoireeEvent decodeEvent(String type, Map<String, Object?> payload) =>
    switch (type) {
      EventTypes.gameStarted => GameStarted(
        players: [
          for (final p in payload['players']! as List)
            Player(id: p['id'] as String, name: p['name'] as String),
        ],
        config: X01Config(
          startScore: payload['startScore']! as int,
          outRule: OutRule.values.byName(payload['outRule']! as String),
        ),
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
      EventTypes.soireeEnded => const SoireeEnded(),
      _ => throw FormatException('Unknown event type "$type"'),
    };
