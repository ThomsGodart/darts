# 03: Cycle Session 4 jeux + historique minimal

**What to build:** Depuis la fin d’une partie, « Changer… » permet d’enchaîner X01 ↔ Cricket ↔ Killer ↔ Shanghai dans la même Session. L’historique liste chaque partie avec type + options courtes + gagnant (score Shanghai ou résumé vies Killer). Pas de nouvelles métriques type MPR/% doubles.

**Blocked by:** 01 Shanghai jouable E2E, 02 Killer jouable E2E

**Status:** resolved

- [x] Changer… ouvre le setup cartes avec les 4 kinds et démarre le kind choisi
- [x] Rejouer reste kind-local (Killer ré-attribue ; Shanghai garde options)
- [x] Lignes historique + détail Session lisibles pour Killer et Shanghai
- [x] Tests cycle mixte (au moins un enchaînement cross-kind) + formatage historique
