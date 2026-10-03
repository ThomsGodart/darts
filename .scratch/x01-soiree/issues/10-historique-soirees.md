# 10: Historique des soirées

**What to build:** On consulte la liste des soirées passées (date, joueurs, nombre de parties). Le détail d’une soirée montre chaque partie avec son gagnant et la moyenne 3 fléchettes par joueur, plus la moyenne de chacun sur la soirée. On peut supprimer une soirée de l’historique. L’historique se calcule en rejouant les journaux persistés. Voir spec : Persistance, user stories 46–48.

**Blocked by:** 09 (Fin de partie, Rejouer et cycle de soirée).

**Status:** ready-for-agent

- [x] Tests de façade : plusieurs soirées persistées → la liste et les détails exposent les bons gagnants et les bonnes moyennes
- [x] La suppression d’une soirée la retire de la liste et de la base
- [x] Écrans liste et détail accessibles depuis l’accueil
- [x] Fonctionne offline

## Comments

- 2026-10-03 — Implémenté :
  - Port `SoireeRepository.history()` (soirées avec au moins une partie, la plus récente d’abord, rejouées depuis leur journal) et `delete(id)`, en mémoire et en drift, avec un contrat commun.
  - `SoireeState.players` : joueurs dans l’ordre de première apparition, sous leur dernier nom.
  - Écrans « Historique » (date en français, joueurs, nombre de parties, pastille « en cours » pour la soirée ouverte) et détail : moyennes de la soirée, puis chaque partie avec sa config, son gagnant (ou « Non terminée » pour une partie abandonnée) et les moyennes.
  - Suppression avec confirmation. Supprimer la soirée ouverte retire aussi « Reprendre la soirée ».
