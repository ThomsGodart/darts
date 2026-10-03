# 02: Session polymorphe + persistance

**What to build:** Une Session peut démarrer une partie X01 **ou** Cricket. `GameStarted` (ou équivalent) porte un kind + config discriminée. Codec événements + migration Drift si besoin. `startGame` / `rematch` / refus « déjà en cours » restent cohérents. Reprise d’une partie Cricket en cours via le journal. Voir spec : Implementation Notes, Depends on.

**Blocked by:** 01

**Status:** ready-for-human

- [ ] Modèle de config / état de partie discriminé (X01 | Cricket) sans casser les tests X01 existants
- [ ] `encodeEvent` / `decodeEvent` + tests round-trip
- [ ] Migration DB si le schéma / types d’events changent ; test vN → current
- [ ] Contrat repository : create / resume / flush inchangés pour X01 ; Cricket survit à un relaunch

## Comments
