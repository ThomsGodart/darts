# Game kind names are the stored tags

Every `game_started` event stores which **game kind** it started. That tag is the name of the `GameKind` enum value (`x01`, `cricket`, `shanghai`, `killer`), reached through `GameConfig.kind`, instead of a separate table of strings in the codec.

The kind used to exist three times: the sealed `GameConfig` type, a `GameKind` enum owned by the setup screen, and a `GameKinds` string table in the codec. A new kind could be forgotten in the codec, and the setup read any config it did not know as X01. With one enum, the compiler flags every place a new kind is missing.

## Consequences

- Renaming a `GameKind` value silently breaks every stored journal. Treat the names as a storage format: add values, never rename them. `test/session/stored_journal_test.dart` pins the stored names and replays a journal as stored.
- A `game_started` event with no `kind` is an X01 game: journals written before kinds existed hold nothing else.
