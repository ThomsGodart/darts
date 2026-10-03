# 09: Fin de partie, Rejouer et cycle de soirée

**What to build:** À la fin d’une partie, un écran montre le gagnant et la moyenne 3 fléchettes de chacun. « Rejouer » relance en un tap une partie avec la même config, et le premier joueur tourne à chaque partie. On peut aussi changer 501/301 ou le Double-out avant de rejouer. Entre deux parties, on peut ajouter un joueur arrivé en retard ou en retirer un parti. On peut terminer la soirée explicitement. L’état de la soirée liste ses parties et la moyenne de chaque joueur sur la soirée. Voir spec : Façade (commandes rejouer / ajouter / retirer / terminer), user stories 11–13, 40–43.

**Blocked by:** 08 (Joueurs + setup de soirée).

**Status:** ready-for-agent

- [x] Tests de façade : rotation du premier joueur sur plusieurs « Rejouer »
- [x] Tests de façade : rejouer avec une config modifiée
- [x] Tests de façade : ajout et retrait de joueur entre deux parties ; rejet typé pendant une partie
- [x] Tests de façade : moyenne de soirée par joueur sur plusieurs parties
- [x] Écran de fin de partie avec « Rejouer » en un tap (< 5 s jusqu’à la volée suivante) et « Terminer la soirée »

## Comments

- 2026-10-03 — Implémenté :
  - `Soiree.rematch({config})` relance avec l’ordre de la partie précédente décalé d’un cran : celui qui a commencé lance en dernier.
  - Ajout / retrait / réordonnancement entre deux parties = un nouveau `startGame` avec la nouvelle liste (refusé pendant une partie). Côté UI, « Changer… » ouvre le setup prérempli (« Partie suivante »).
  - `endSoiree()` → événement `SoireeEnded`, possible seulement entre deux parties, avec confirmation à l’écran. Une soirée terminée refuse tout.
  - `SoireeState.games` (toutes les parties) et `averageOf(player)` sur la soirée.
  - Fin de partie : gagnant, tableau des moyennes (partie + soirée dès la 2e partie), « Rejouer » en un tap, « Changer… », « Annuler le checkout », « Terminer la soirée ».
  - « Reprendre la soirée » = dernière soirée non terminée, même entre deux parties.
- Corrigé au passage : `setState` de l’accueil renvoyait un Future (bug latent depuis le ticket 07, visible au retour à l’accueil).
- 2026-10-03 — Suite à la code review :
  - « Nouvelle soirée » alors qu’une soirée est ouverte demande confirmation, puis termine l’ancienne (même en pleine partie, la partie reste inachevée) : plus de soirée orpheline jamais terminée.
  - Une soirée terminée refuse toute saisie.
  - Moyenne de soirée par id de joueur : un renommage entre deux parties ne coupe plus la moyenne en deux. Le setup prérempli reprend les noms à jour du catalogue.
  - « Changer… » est protégé contre le double tap et affiche une erreur au lieu de la laisser remonter.
  - Le test widget ne vérifie plus les règles (moyenne, rotation), qui sont couvertes par la façade.
  - Spec amendée : événements réellement utilisés, commandes « démarrer une partie suivante » et « terminer / abandonner ».
