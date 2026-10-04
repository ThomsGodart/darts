/// Whoever holds a score in a game: a person, a team of them, or a
/// virtual opponent.
class Player {
  const Player({
    required this.id,
    required this.name,
    this.members = const [],
    this.botAverage,
  });

  /// A team: one side of a game, its [members] taking turns to throw.
  Player.team(List<Player> members)
    : this(
        id: 'team:${members.map((m) => m.id).join('+')}',
        name: members.map((m) => m.name).join(' & '),
        members: List.unmodifiable(members),
      );

  /// A virtual opponent throwing to a three-dart [average].
  Player.bot(int average)
    : this(id: 'bot:$average', name: 'Bot $average', botAverage: average);

  final String id;
  final String name;

  /// The people of a team, in the order they throw; empty for anyone
  /// playing alone.
  final List<Player> members;

  /// The three-dart average a virtual opponent throws to; null for
  /// people.
  final int? botAverage;

  bool get isTeam => members.isNotEmpty;

  bool get isBot => botAverage != null;

  @override
  bool operator ==(Object other) =>
      other is Player && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'Player($id, $name)';
}

/// The people behind [players], who have a place in the catalog: team
/// members rather than their team, and no virtual opponent.
List<Player> peopleOf(Iterable<Player> players) => [
  for (final player in players)
    for (final person in player.isTeam ? player.members : [player])
      if (!person.isBot) person,
];
