# Domain glossary

Terms used in code, tests, specs and tickets. Code is in English; the UI is
in French.

| Term | Meaning | UI (fr) |
| --- | --- | --- |
| **Session** | A group of players chaining games in one sitting, whatever the time of day. Ends explicitly, then goes to the history. Never "night" or "soirée". | session |
| **Game** | One game inside a session, of one **game kind** (X01, Cricket, Shanghai, Killer, Halve-It, Golf, Around the Clock, Bob's 27, Count-Up or Baseball), with its own config and winner. | partie |
| **Game kind** | Which game is played; a game's config says its kind. Stored by name with every game started. | — |
| **Leg** | An X01 game that is part of a match. | manche |
| **Set** | A group of legs: the first to the legs asked takes the set. | set |
| **Match** | X01 legs chained with the same players and rules, won by the first to the legs asked, or to the sets asked. Not stored: it is read off the session's consecutive games. | match |
| **Rematch** | The next game with the same players and rules; whoever started last throws last. | Rejouer |
| **Visit** | One player's turn: up to three darts (a **round** for Cricket MPR). Entered as a total or dart by dart in X01 and Count-Up; dart by dart only in the other games. A visit ended early counts its missing darts as misses, except in Golf, where the last dart thrown stands. | volée |
| **Dart** | One throw: a sector (1–20, 25) with a multiplier (single, double, treble), or a miss. | fléchette |
| **Remaining** | Points a player still has to score in X01. | reste |
| **Bust** | A visit that would leave the remaining below 0, on 1 in double-out, or on 0 without a double; it scores nothing. | BUST |
| **Checkout** | The visit that brings the remaining to exactly 0 and wins the game. | checkout |
| **Out rule** | How a game must be finished: straight-out (any dart) or double-out (a double or the bull). | Double-out |
| **Mark** | A hit count toward closing a Cricket number (need 3; S/D/T = 1/2/3; outer/inner bull = 1/2). | marque |
| **MPR** | Marks per round (visit) in Cricket. | MPR |
| **Killer** | Party game: claim a number, become Killer on its double, remove lives on others’ doubles. | Killer |
| **Shanghai** | Fixed number sequence; score S/D/T on that number; optional instant win on S+D+T in one visit. | Shanghai |
| **Halve-It** | Fixed targets (20, 16, D7, 14, T10, 17, bull), everyone starting on 40; hits on the target add up, a visit without one halves the score, rounding up. Highest score wins. | Halve-It |
| **Golf** | Hole n is the number n, over 9 or 18 holes. Up to three darts, the last one thrown counts: double 1 **stroke**, treble 2, single 3, anything else 5. Fewest strokes win. | Golf |
| **Stroke** | What a Golf hole costs a player. | coup |
| **Around the Clock** | Hit 1 to 20 in order, any ring counting, optionally finishing on the bull. The first to finish wins at once. | Tour de l'horloge |
| **Bob's 27** | Everyone starts on 27 and throws three darts at each double from D1 to D20, then the bull. Each hit adds the target's value, a visit without one takes it away; at zero or less a player is out. Highest score wins. | Bob's 27 |
| **Count-Up** | Every dart scores what it is worth, over 8 or 10 rounds. Highest total wins. | Count-Up |
| **Baseball** | Nine **innings**: inning n is thrown at the number n, a single scoring 1 run, a double 2, a treble 3. Most runs win; a tie for the lead plays extra innings. | Baseball |
| **Round** | In Count-Up, Shanghai, Halve-It, Golf and Bob's 27: one visit by every player on the same target. (Cricket's MPR counts a player's own visits as their rounds.) | manche |
| **Inning** | A round of Baseball. | manche |
| **Run** | What a dart on the inning's number scores in Baseball. | run |
| **Player catalog** | The players known to the app across sessions; players who played are archived, not deleted. | joueurs |
| **Journal** | The ordered events of a session; the session's state is a fold of it. | — |
