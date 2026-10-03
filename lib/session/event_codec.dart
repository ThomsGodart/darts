import 'dart.dart';
import 'events.dart';
import 'player.dart';
import 'x01_config.dart';

/// Stable type tags stored with each event. Renaming one breaks every
/// stored journal unless a database migration rewrites it too (as the
/// schema v3 migration did for `soiree_ended` → `session_ended`).
abstract final class EventTypes {
  static const gameStarted = 'game_started';
  static const visitTotalSubmitted = 'visit_total_submitted';
  static const dartThrown = 'dart_thrown';
  static const sessionEnded = 'session_ended';
}

/// A storable form of an event: a type tag and a JSON-compatible payload.
typedef EncodedEvent = ({String type, Map<String, Object?> payload});

EncodedEvent encodeEvent(SessionEvent event) => switch (event) {
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
  SessionEnded() => (type: EventTypes.sessionEnded, payload: const {}),
};

SessionEvent decodeEvent(String type, Map<String, Object?> payload) =>
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
      EventTypes.sessionEnded => const SessionEnded(),
      _ => throw FormatException('Unknown event type "$type"'),
    };
