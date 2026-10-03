# 02: Tracer bullet : une partie de Cricket Standard

**What to build:** Depuis le setup, on choisit « Cricket » au lieu de « X01 » et on joue une partie de Cricket Standard de bout en bout, fléchette par fléchette.
- **Règles :**
  - seuls 15–20 et Bull marquent : simple 1, double 2, triple 3, 25 = 1 marque de Bull, Bull = 2 ;
  - un chiffre est fermé à 3 marques ; les marques en trop rapportent des points tant qu’un adversaire ne l’a pas fermé ;
  - un chiffre fermé par tous est mort ;
  - on gagne dès qu’on a tout fermé avec au moins autant de points que chaque adversaire ;
  - la volée se termine à la 3e fléchette ou à la victoire.
- **Écran de jeu :** une grille (une ligne par chiffre, 20 en haut, Bull en bas ; une colonne par joueur ; marques /, X, Ⓧ), les points sous la grille, les fléchettes de la volée en cours. Le tiroir de saisie ne propose que le sélecteur de fléchettes.
- **Repris tels quels :** undo, reprise après relance, « Rejouer » (même variante, rotation du premier joueur), fin de session.

Voir spec : US 1, 5–12, 14, 15, 17–21, 25 ; Implementation Decisions (Moteur Cricket, Événements, UI).

**Blocked by:** 01 (Prefactor : GameConfig scellée + état de partie commun / X01).

**Status:** ready-for-agent

- [x] Tests de façade : marques de chaque fléchette (15–20 en S/D/T, 25, Bull, secteurs 1–14, raté)
- [x] Tests de façade : fermeture, points en Standard, chiffre mort
- [x] Tests de façade : victoire Standard (égalité de points comprise) ; pas de victoire tant qu’un chiffre reste ouvert
- [x] Tests de façade : fin de volée à la 3e fléchette ou à la victoire ; undo sur plusieurs volées et après la victoire ; saisie par total refusée
- [x] Contrat de repository : une session mixte X01 + Cricket se rejoue à l’identique après relance
- [x] Setup : choix X01 / Cricket ; écran de jeu : grille Cricket et tiroir limité aux fléchettes (tests widget UI seulement)

## Comments

- 2026-10-03 — Implémenté :
  - Domaine :
    - `CricketConfig` (variante `standard`), `CricketGame` / `CricketScore` (marques plafonnées à 3, points, volées).
    - `Dart.cricketMarks` : 15–20 et Bull uniquement ; 25 = 1 marque, Bull = 2.
    - Règles dans le fold : fermeture, points sur les marques en trop tant qu’un adversaire est ouvert, chiffre mort, victoire dès que tout est fermé avec au moins autant de points, fin de volée à la 3e fléchette ou à la victoire.
    - Codec `kind: "cricket"` + `variant`.
  - UI :
    - Setup « X01 / Cricket ».
    - `CricketBoard` : grille avec marques / X Ⓧ, chiffres morts barrés, points.
    - Tiroir réduit au sélecteur de fléchettes.
    - Fin de partie avec les points (le MPR arrive au ticket 04).
    - Historique : libellé « Cricket » et points par partie.
  - Les tokens dédiés à la grille sont au ticket 05 ; pour l’instant, la grille réutilise les tokens du joueur actif.
