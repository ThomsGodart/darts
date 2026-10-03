# 02: Killer jouable E2E

**What to build:** Une Session peut démarrer Killer (3–8 joueurs, vies 3|5, N doubles pour devenir Killer défaut 1). Phase attribution (tirage in-app ou choix manuel, doublons refusés) puis phase jeu sur grille doubles (1–20 + miss) : devenir Killer, −1 vie adversaire / self-hit, OUT à 0 (tours skippés, toujours visible), dernier en vie gagne. Undo, Rejouer avec **nouvelle** attribution, reprise après kill d’app. Écran de fin Session-standard.

**Blocked by:** None (can start immediately) — requires v1.1 ; parallel with 01.

**Status:** resolved

- [x] Carte setup Killer + options vies / N ; refus hors 3–8 joueurs
- [x] State machine `assigning | playing | finished` + events attribution + fold vies/OUT/win
- [x] Persist/resume journal (`kind` killer) avec tests codec/migration
- [x] UI : attribution claire vs grille doubles ; bannière/haptique/wakelock ; fin + rematch ré-attribue
- [x] Tests façade (self-hit, last standing, skip OUT, doublon refusé, undo) + smoke widget
