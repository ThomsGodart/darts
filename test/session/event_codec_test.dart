import 'package:darts_points_counter/session/event_codec.dart';
import 'package:darts_points_counter/session/events.dart';
import 'package:darts_points_counter/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SessionEvent roundTrip(SessionEvent event) {
    final encoded = encodeEvent(event);
    return decodeEvent(encoded.type, encoded.payload);
  }

  test('an ended visit is stored as such', () {
    expect(roundTrip(const VisitEnded()), isA<VisitEnded>());
  });

  test('a cricket game keeps how it is entered', () {
    for (final input in CricketInput.values) {
      final event = GameStarted(
        players: const [Player(id: 'a', name: 'A')],
        config: CricketConfig(input: input),
      );
      expect((roundTrip(event) as GameStarted).config, event.config);
    }
  });

  test('cricket games recorded before the choice used the keypad', () {
    final encoded = encodeEvent(
      const GameStarted(
        players: [Player(id: 'a', name: 'A')],
        config: CricketConfig(),
      ),
    );
    final decoded = decodeEvent(
      encoded.type,
      Map.of(encoded.payload)..remove('input'),
    );
    expect(
      (decoded as GameStarted).config,
      const CricketConfig(input: CricketInput.keypad),
    );
  });
}
