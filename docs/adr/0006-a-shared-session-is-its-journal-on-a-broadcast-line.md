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
- A device that was cut off catches up when its line is back; if it went on alone meanwhile and is ahead, the others take its journal.
- Messages are typed and carry a protocol version (`share_protocol.dart`). A build that speaks another one is not read, and the players are told to update; an event one side does not know makes it refuse the other's journal rather than break. Renaming a stored event type breaks sharing between versions as it breaks stored journals.
- Every device throws for virtual opponents, a guest only after waiting long enough for the device that shares to have done it: the game does not stall when that device is away, and two devices do not throw twice.
- A broadcast message is capped (256 kB on the free plan): a whole journal of several thousand events would not pass. Only a device joining or catching up receives one.

## What the code protects, and what it does not

The line is public: the publishable key ships in the app, and a code is six digits. Without a server that authenticates devices, anyone who finds a live code can watch the game and send journals. Since the session is stored by the device that shares it, that device is where the damage is bounded:

- It does not take from the line a journal that changes anything before the game in hand: games already played, their stats and the history cannot be rewritten or erased by another device. It answers with its own journal, at a version above.
- It may lock the input, and then takes nothing at all.
- It does not end its session on a `gone` signal: only guests do.
- Journals above a size nothing played comes near are not read.

What is left: someone who guesses a live code can spoil the game in hand, append games, or end the session, until the players stop the share. Closing that needs devices to prove who they are — private Realtime channels with sign-in and row-level security — which is the Postgres option above.
