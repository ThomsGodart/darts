# 01: Prefactor : GameConfig scellée + état de partie commun / X01

**What to build:** Préparer la façade `Session` à plusieurs types de partie, sans aucun changement de comportement visible.
- `GameStarted` porte une `GameConfig` scellée. `X01Config` en est pour l’instant la seule implémentation ; `CricketConfig` arrive au ticket 02.
- `GameState` est découpé en une partie commune (joueurs, ordre, joueur actif, fléchettes de la volée en cours, gagnant, volées jouées) et un état propre au X01 (restes, visites, checkout, moyenne).
- Le codec écrit un champ `kind: "x01"` dans `game_started`. Un `game_started` sans `kind` (journaux v1) se lit comme X01, sans migration de base.

Voir spec : Implementation Decisions (Configuration de partie, État de partie, Codec).

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [x] Les tests X01 existants passent sans modification de leurs assertions (seuls les imports ou noms de types peuvent bouger)
- [x] Un journal enregistré avant ce ticket (sans `kind`) se rejoue à l’identique, testé par le contrat de repository
- [x] `flutter analyze` propre ; aucun changement d’UI

## Comments

- 2026-10-03 — Implémenté :
  - `GameConfig` scellée (`x01_config.dart` → `game_config.dart`) et `Game` scellé (champs communs : joueurs, joueur actif, fléchettes de la volée, gagnant, volées jouées, ordre de revanche).
  - `GameState` devient `X01Game`.
  - Le fold et l’UI aiguillent selon le type de partie.
  - `submitVisitTotal` est refusé hors X01.
  - Le codec écrit `kind: "x01"` ; l’absence de `kind` se lit comme X01, ce que couvre `migration_test` (journaux v1 et v2 sans `kind`).
- Tests : seules les lectures X01 ont changé, via l’accès `state.x01!` dans les helpers. Aucune assertion n’a été modifiée.
