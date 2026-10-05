# Ending a visit early is one journal event

A player can end their **visit** before its third dart ("Fin de tour"). We record that as a single `VisitEnded` event, and the fold fills the missing darts with misses. One undo therefore takes the whole end of visit back. Golf is the exception to the misses: there a player stops on a dart they like, so `VisitEnded` keeps the last dart thrown.

The first version looped `throwDart(miss)` from the game screen, journaling one or two `DartThrown` events. It needed no new event type, but one undo removed only one of the padded misses and left the next player inside a visit they never started, and the rule lived in a widget where only full-app tests reached it.

## Considered options

- **Padded `DartThrown` misses plus a grouped undo.** Keeps the journal vocabulary unchanged, but the journal could no longer tell a thrown miss from a padded one, and undo would need to guess the group.
- **`VisitEnded` event (chosen).** The journal says what the player did.

## Consequences

- `visit_ended` is a stored event type: like the others in `EventTypes`, it must never be renamed without a database migration.
- A build older than this one cannot read a journal that contains it.
- The padded darts count as thrown: an X01 visit ended early is a three-dart visit in the average.

## Update: every visit entered dart by dart is ended by the players

Players lost sight of a visit the moment its third dart was entered: the turn passed, and the board showed the next thrower. A visit now stays open after its last dart — and an X01 visit after the dart that busts it — until `VisitEnded`. Only a dart that wins the game ends the visit by itself.

`VisitEnded` therefore no longer means "early": it is how every visit entered dart by dart ends, and the fold completes the visit there rather than on the third `DartThrown`.

Journals written before this hold three darts with no `VisitEnded` after them, and a `VisitEnded` right after three darts in them is the *next* player passing. They cannot be told apart from the events alone, so `GameStarted` says which rule its game was journaled under: `confirmsVisits`, stored only when true. A game without the key is folded the old way, the turn passing on the third dart.

- `confirmsVisits` is a stored key: never rename it without a migration.
- A total that reaches 0 can be stored as a bust (`bust: true` on `visit_total_submitted`) when the players say its last dart was not a finishing one.
