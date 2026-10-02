import 'events.dart';
import 'player.dart';
import 'x01_config.dart';

/// Stable type tags stored with each event. Never rename one: stored
/// journals would no longer replay.
abstract final class EventTypes {
  static const gameStarted = 'game_started';
  static const visitTotalSubmitted = 'visit_total_submitted';
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
      _ => throw FormatException('Unknown event type "$type"'),
    };
