# The Cricket input mode lives in the game config

A Cricket game is entered either on the board (single / double / treble keys between the players' columns) or on the dart keypad. The choice is made in the setup and stored in `CricketConfig.input`, next to the variant, although it is not a rule of the game.

It is there because the config is the only thing that travels with a game: it is recorded in the journal, so the choice survives resuming the session, "Rejouer" and "Partie suivante" without any other storage. The app has no settings store yet.

## Considered options

- **A user preference outside the domain.** The honest home for a UI choice, but it needs a preferences store the app does not have, and a resumed game would follow the current preference rather than the one it was started with.
- **A toggle on the game screen.** No storage at all, but the choice was asked for at launch and would be lost on resume.

## Consequences

- Two Cricket configs that differ only by `input` are not equal, and the history keeps how each game was entered.
- Cricket games stored before the choice existed have no `input`: they read as `keypad`, what they were played with.
- If a settings store arrives, moving the choice there means reading `input` from old journals and ignoring it.
