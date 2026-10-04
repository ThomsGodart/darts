# A match is read off consecutive games

An X01 match (first to N legs, optionally in sets) is not a thing the journal knows about. `X01Config` carries `legsToWin` and `setsToWin`, each leg is an ordinary game, and the match score is derived: the latest run of X01 games with the same config and the same players, in any order, a decided match ending its run (`lib/session/match.dart`).

So "Rejouer" needed no change: after a won leg it plays the next leg, starter rotated as before, and after a won match it starts a new one. Undo, resume and the history got matches for free, because they only ever replay games.

## Considered options

- **Match events in the journal** (`MatchStarted`, legs tagged with a match id). Says exactly where a match starts and ends, but adds stored event types and a second place the state can disagree with the games.
- **Derived from the games (chosen).**

## Consequences

- Starting a game through the setup with the same players and the same rules continues the match in progress rather than starting a new one. Changing anything (a player, the start score, the legs to win) starts a new match.
- Leaving a match unfinished and playing another game in between ends its run: coming back to the same rules starts from 0–0.
- `legsToWin` and `setsToWin` are stored with every X01 game; games stored before they existed read as single legs.
