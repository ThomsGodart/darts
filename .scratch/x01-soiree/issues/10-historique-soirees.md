# 10: Historique des soirées

**What to build:** On consulte la liste des soirées passées (date, joueurs, nombre de parties). Le détail d’une soirée montre chaque partie avec son gagnant et la moyenne 3 fléchettes par joueur, plus la moyenne de chacun sur la soirée. On peut supprimer une soirée de l’historique. L’historique se calcule en rejouant les journaux persistés. Voir spec : Persistance, user stories 46–48.

**Blocked by:** 09 (Fin de partie, Rejouer et cycle de soirée).

**Status:** ready-for-agent

- [ ] Tests de façade : plusieurs soirées persistées → la liste et les détails exposent les bons gagnants et les bonnes moyennes
- [ ] La suppression d’une soirée la retire de la liste et de la base
- [ ] Écrans liste et détail accessibles depuis l’accueil
- [ ] Fonctionne offline
