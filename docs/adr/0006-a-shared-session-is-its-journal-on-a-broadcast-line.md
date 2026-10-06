# A shared session is its journal on a broadcast line

Two phones play one session: typically one set down as the scoreboard, the other in hand to enter. Since a session is nothing but its journal, sharing one is making several devices hold the same journal. They exchange it over Supabase Realtime **broadcast**, on a channel named after a six-digit code: no table, no account, nothing stored on the server (`lib/share/`).

Every change of the journal gets a version: a count, and the device that made it. A device sends what changed since the version before (how many events to keep, then the new tail); one that receives a change built on a version it does not hold asks for the whole journal. The higher version always stands, so every device ends on the same journal. Incoming journals are folded before they are taken, and refused if the fold trips.

The session is stored by the device that shares it, through its usual repository. A device that joins only holds it in memory: it has no history or stats of it.

## Considered options

- **Journals in Postgres, synced through tables and row-level security.** Survives the host leaving and gives every device a history, but needs a schema, accounts or anonymous sign-in, a mapping between each phone's player catalog, and conflict rules for the stored copy. Too much for a second screen.
- **Commands sent to a host that owns the journal.** No conflicts, but the phone that enters would wait on the network for every dart, and nothing works when the host drops.
- **The whole journal on a broadcast line (chosen).** Every device plays from its own copy at once; the line only has to carry the difference.

## Consequences

- Two inputs made at the same instant on two devices: one stands, the other is lost, and the players see it on every screen. There is no merge.
- Anyone who knows the code can watch and enter while the session is shared. The code is not a secret worth more than a game of darts; the publishable key in the app only opens broadcast.
- A device that was cut off catches up when its line is back; if it went on alone meanwhile and is ahead, the others take its journal.
- Events now travel between app versions: an event one side does not know makes it ignore the other's journal rather than break. Renaming a stored event type breaks sharing between versions as it breaks stored journals.
- Only the device that shares throws for virtual opponents, or two devices would throw twice.
- A broadcast message is capped (256 kB on the free plan): a whole journal of several thousand events would not pass. Only a device joining or catching up receives one.
