# 01: Prefactor : GameConfig scellée + état de partie commun / X01

**What to build:** Préparer la façade `Session` à plusieurs types de partie, sans aucun changement de comportement visible.
- `GameStarted` porte une `GameConfig` scellée. `X01Config` en est pour l’instant la seule implémentation ; `CricketConfig` arrive au ticket 02.
- `GameState` est découpé en une partie commune (joueurs, ordre, joueur actif, fléchettes de la volée en cours, gagnant, volées jouées) et un état propre au X01 (restes, visites, checkout, moyenne).
- Le codec écrit un champ `kind: "x01"` dans `game_started`. Un `game_started` sans `kind` (journaux v1) se lit comme X01, sans migration de base.

Voir spec : Implementation Decisions (Configuration de partie, État de partie, Codec).

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [ ] Les tests X01 existants passent sans modification de leurs assertions (seuls les imports ou noms de types peuvent bouger)
- [ ] Un journal enregistré avant ce ticket (sans `kind`) se rejoue à l’identique, testé par le contrat de repository
- [ ] `flutter analyze` propre ; aucun changement d’UI
