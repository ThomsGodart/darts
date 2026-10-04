/// The `Session` domain: a group of players chaining X01 games.
///
/// Pure Dart, no Flutter, no database. [Session] is the single entry point;
/// everything else exported here is its vocabulary.
library;

export 'checkout.dart' show maxCheckoutSuggestion;
export 'commands.dart';
export 'dart.dart';
export 'events.dart' show SessionEvent;
export 'journal.dart';
export 'match.dart';
export 'player.dart';
export 'player_catalog.dart';
export 'player_stats.dart';
export 'repository.dart';
export 'session_facade.dart';
export 'state.dart';
export 'game_config.dart';
