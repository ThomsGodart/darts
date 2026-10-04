# Teams and virtual opponents are players

A game is played between sides, and every game only knows `Player`s holding a score. Rather than teach ten games about teams, a team **is** a `Player`: its id and name are built from its `members`, it holds one score like anyone, and `Game.thrower` says which member is at the oche (members alternate round after round). A virtual opponent is a `Player` too, with a `botAverage`.

Both are stored inside `game_started`, as optional keys of a player (`members`, `botAverage`), so journals written before them read unchanged.

## Considered options

- **A `Team` type and per-team scores in every game.** Models doubles exactly, but touches the state, the fold, the board and the stats of all ten games.
- **Teams as players (chosen).** No game changed; rematch, undo, resume and the history work as they did.

## Consequences

- A team's stats are not split between its members: who threw which visit is not recorded, only derived from the round. Teams and virtual opponents are left out of the per-player stats.
- The thrower is derived from the number of visits played, which assumes sides throw in strict rotation. In games that skip eliminated players (Killer, Bob's 27) the member announced can drift once someone is out.
- A virtual opponent only plays games entered as a total: the app enters its visits through the same command a person's total goes through.
- The setup asks for a number of teams and lets each picked player choose theirs, so teams can be uneven (two against three); someone alone in a team is stored as themselves, not as a team of one. A team is flattened back into its members when the setup is reopened.
