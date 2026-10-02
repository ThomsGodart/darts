/// The `Soirée` domain: a group of players chaining X01 games.
///
/// Pure Dart, no Flutter, no database. [Soiree] is the single entry point;
/// everything else exported here is its vocabulary.
library;

export 'commands.dart';
export 'events.dart' show SoireeEvent;
export 'journal.dart';
export 'player.dart';
export 'soiree_facade.dart';
export 'state.dart';
export 'x01_config.dart';
