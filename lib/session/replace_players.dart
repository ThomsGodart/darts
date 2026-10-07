import 'events.dart';
import 'player.dart';

/// [events] with the people in them replaced as [byId] says, keyed by
/// the id they have there: for a journal that came from another device,
/// whose catalog gave the same people other ids. A team is rebuilt from
/// its replaced members; virtual opponents, and anyone [byId] leaves
/// out, stay as they are.
List<SessionEvent> replacePlayers(
  List<SessionEvent> events,
  Map<String, Player> byId,
) {
  Player replaced(Player player) => player.isTeam
      ? Player.team([for (final member in player.members) replaced(member)])
      : byId[player.id] ?? player;
  return [
    for (final event in events)
      if (event is GameStarted)
        GameStarted(
          players: List.unmodifiable(event.players.map(replaced)),
          config: event.config,
          confirmsVisits: event.confirmsVisits,
        )
      else
        event,
  ];
}

/// The people who played in [events], each once, in the order they first
/// appear.
List<Player> peopleIn(List<SessionEvent> events) {
  final people = <String, Player>{};
  for (final event in events) {
    if (event is GameStarted) {
      for (final person in peopleOf(event.players)) {
        people.putIfAbsent(person.id, () => person);
      }
    }
  }
  return people.values.toList();
}

/// Whether anything was entered into the games of [events].
bool hasInput(List<SessionEvent> events) =>
    events.any((event) => event is! GameStarted && event is! SessionEnded);
