# 09: Fin de partie, Rejouer et cycle de soirée

**What to build:** À la fin d’une partie, un écran montre le gagnant et la moyenne 3 fléchettes de chacun. « Rejouer » relance en un tap une partie avec la même config, et le premier joueur tourne à chaque partie. On peut aussi changer 501/301 ou le Double-out avant de rejouer. Entre deux parties, on peut ajouter un joueur arrivé en retard ou en retirer un parti. On peut terminer la soirée explicitement. L’état de la soirée liste ses parties et la moyenne de chaque joueur sur la soirée. Voir spec : Façade (commandes rejouer / ajouter / retirer / terminer), user stories 11–13, 40–43.

**Blocked by:** 08 (Joueurs + setup de soirée).

**Status:** ready-for-agent

- [ ] Tests de façade : rotation du premier joueur sur plusieurs « Rejouer »
- [ ] Tests de façade : rejouer avec une config modifiée
- [ ] Tests de façade : ajout et retrait de joueur entre deux parties ; rejet typé pendant une partie
- [ ] Tests de façade : moyenne de soirée par joueur sur plusieurs parties
- [ ] Écran de fin de partie avec « Rejouer » en un tap (< 5 s jusqu’à la volée suivante) et « Terminer la soirée »
