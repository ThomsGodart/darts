# 02: Killer jouable E2E

**What to build:** Une Session peut démarrer Killer (3–8 joueurs, vies 3|5, N doubles pour devenir Killer défaut 1). Phase attribution (tirage in-app ou choix manuel, doublons refusés) puis phase jeu sur grille doubles (1–20 + miss) : devenir Killer, −1 vie adversaire / self-hit, OUT à 0 (tours skippés, toujours visible), dernier en vie gagne. Undo, Rejouer avec **nouvelle** attribution, reprise après kill d’app. Écran de fin Session-standard.

**Blocked by:** None (can start immediately) — requires v1.1 ; parallel with 01.

**Status:** ready-for-agent

- [ ] Carte setup Killer + options vies / N ; refus hors 3–8 joueurs
- [ ] State machine `assigning | playing | finished` + events attribution + fold vies/OUT/win
- [ ] Persist/resume journal (`kind` killer) avec tests codec/migration
- [ ] UI : attribution claire vs grille doubles ; bannière/haptique/wakelock ; fin + rematch ré-attribue
- [ ] Tests façade (self-hit, last standing, skip OUT, doublon refusé, undo) + smoke widget
