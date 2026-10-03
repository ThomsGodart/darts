# Ending a visit early is one journal event

A player can end their **visit** before its third dart ("Fin de tour"). We record that as a single `VisitEnded` event, and the fold fills the missing darts with misses. One undo therefore takes the whole end of visit back.

The first version looped `throwDart(miss)` from the game screen, journaling one or two `DartThrown` events. It needed no new event type, but one undo removed only one of the padded misses and left the next player inside a visit they never started, and the rule lived in a widget where only full-app tests reached it.

## Considered options

- **Padded `DartThrown` misses plus a grouped undo.** Keeps the journal vocabulary unchanged, but the journal could no longer tell a thrown miss from a padded one, and undo would need to guess the group.
- **`VisitEnded` event (chosen).** The journal says what the player did.

## Consequences

- `visit_ended` is a stored event type: like the others in `EventTypes`, it must never be renamed without a database migration.
- A build older than this one cannot read a journal that contains it.
- The padded darts count as thrown: an X01 visit ended early is a three-dart visit in the average.
