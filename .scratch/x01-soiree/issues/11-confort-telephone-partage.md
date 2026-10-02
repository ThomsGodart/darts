# 11: Confort téléphone partagé

**What to build:** À chaque changement de tour, une bannière affiche le nom du joueur suivant et le téléphone vibre, pour que celui qui le prend sache que c’est à lui. L’écran ne se met pas en veille pendant une partie. En build debug seulement, un compteur de taps par volée sert à mesurer l’hypothèse ≤ 2 taps en moyenne par volée. Voir spec : UI, Further Notes, user stories 21, 51.

**Blocked by:** 02 (Tracer bullet : une partie 501 par totaux).

**Status:** ready-for-agent

- [x] Bannière + haptique au changement de joueur, sans bloquer la saisie suivante
- [x] Wakelock actif pendant une partie, relâché en dehors
- [x] Compteur de taps (moyenne de taps par volée) visible uniquement en debug
- [x] Aucune pub ni popup intrusive

## Comments

- 2026-10-02 — Implémenté :
  - Bannière « À toi, X ! » en fondu (purement visuelle, elle ne capte pas les taps) avec vibration moyenne à chaque volée terminée. Rien sur un undo.
  - Écran gardé allumé (`wakelock_plus`, derrière l’interface `ScreenAwake`) tant que la partie est en cours. Libéré à la fin de la partie et en quittant l’écran.
  - En debug, compteur « X taps/volée » en haut à droite. Il compte tous les appuis, dialog compris, depuis l’ouverture de l’écran de jeu.
- Haptique et wakelock non vérifiés sur appareil.
