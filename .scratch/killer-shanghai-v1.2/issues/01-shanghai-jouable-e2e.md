# 01: Shanghai jouable E2E

**What to build:** Une Session peut démarrer une partie Shanghai depuis une carte setup (longueur 1–7 / 14–20 / 1–20, option Shanghai instantané défaut on, 1–8 joueurs). Saisie fléchette par fléchette sur la grille S/D/T du chiffre du tour (+ miss / Fin de tour), score cumulé, victoire instantanée S+D+T si option on sinon plus haut score en fin de séquence. Undo, Rejouer (mêmes options, premier tourné), reprise après kill d’app. Écran de fin avec Rejouer / Changer… / Terminer.

**Blocked by:** None (can start immediately) — requires v1.1 Cricket shipped (Session multi-jeux).

**Status:** resolved

- [x] Carte setup Shanghai + options (longueur, instant on/off) ; démarrage &lt; 30 s
- [x] Fold + commandes : séquence, scoring, Shanghai instant, Fin de tour, undo
- [x] Persist/resume journal (`kind` shanghai) avec tests codec/migration
- [x] UI jeu : chiffre du tour, grille S/D/T, confort bannière/haptique/wakelock, écran de fin + rematch
- [x] Tests façade (longueurs, instant on/off, undo) + smoke widget setup→partie→fin
