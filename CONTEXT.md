# Domain glossary

Terms used in code, tests, specs and tickets. Code is in English; the UI is
in French.

| Term | Meaning | UI (fr) |
| --- | --- | --- |
| **Session** | A group of players chaining games in one sitting, whatever the time of day. Ends explicitly, then goes to the history. Never "night" or "soirée". | session |
| **Game** | One leg of X01 (later: one game of Cricket) inside a session, with its own config and winner. | partie |
| **Rematch** | The next game with the same players and rules; whoever started last throws last. | Rejouer |
| **Visit** | One player's turn: up to three darts, entered as a total or dart by dart. | volée |
| **Dart** | One throw: a sector (1–20, 25) with a multiplier (single, double, treble), or a miss. | fléchette |
| **Remaining** | Points a player still has to score in X01. | reste |
| **Bust** | A visit that would leave the remaining below 0, on 1 in double-out, or on 0 without a double; it scores nothing. | BUST |
| **Checkout** | The visit that brings the remaining to exactly 0 and wins the game. | checkout |
| **Out rule** | How a game must be finished: straight-out (any dart) or double-out (a double or the bull). | Double-out |
| **Player catalog** | The players known to the app across sessions; players who played are archived, not deleted. | joueurs |
| **Journal** | The ordered events of a session; the session's state is a fold of it. | — |
