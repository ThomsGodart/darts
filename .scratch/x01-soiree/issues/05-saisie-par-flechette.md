# 05: Saisie fléchette par fléchette

**What to build:** Le joueur peut basculer la volée en cours en mode fléchette par fléchette.
- Chaque fléchette se saisit avec un secteur de 1 à 20 et simple, double ou triple, ou bien outer bull 25, bull 50 ou raté.
- Les fléchettes de la volée en cours s’affichent.
- La volée se termine automatiquement à la 3e fléchette, au bust ou au checkout ; le checkout en Double-out exige un double ou un bull.
- La volée suivante revient en mode total.
- Totaux et fléchettes se mélangent dans une même partie. La moyenne compte les fléchettes réellement lancées.
- L’undo annule une fléchette à la fois.

Voir spec : Mode fléchette par fléchette, Moteur X01, user stories 18, 19, 53.

**Blocked by:** 03 (Règles Double-out complètes).

**Status:** ready-for-agent

- [x] Tests de façade : volée par fléchettes complète, bust en cours de volée (fin immédiate), checkout sur double, refus d’un checkout sur simple en Double-out (bust)
- [x] Tests de façade : partie mélangeant totaux et fléchettes, moyenne exacte (bust en 2 fléchettes = 2 fléchettes comptées)
- [x] Tests de façade : l’undo retire une fléchette de la volée en cours
- [x] UI : bascule pour une volée, sélecteur secteur/multiplicateur/bull/raté, retour au mode total à la volée suivante

## Comments

- 2026-10-02 — Implémenté :
  - Valeur `Dart` (simple / double / triple, 25, Bull, raté) et événement `DartThrown`. `Soiree.throwDart` met fin à la volée tout seul : 3e fléchette, bust (dont « 0 sans double » en Double-out) ou checkout.
  - `GameState.dartsInVisit` / `activeRemaining` affichent le reste en direct.
  - L’undo retire une fléchette à la fois.
  - Une saisie par total est refusée tant qu’une volée est en cours fléchette par fléchette.
  - UI : bascule « Total / Fléchettes » pour la volée. Le sélecteur repasse en Simple après chaque fléchette. La volée suivante revient en mode total, car l’entrée est recréée à chaque volée (clé `visitsPlayed`).
  - La reprise après relance conserve les fléchettes de la volée en cours (codec `dart_thrown`).
