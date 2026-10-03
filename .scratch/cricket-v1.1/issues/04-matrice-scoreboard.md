# 04: Matrice scoreboard Cricket

**What to build:** Widget scoreboard matrice : lignes 20→15+Bull, colonnes = joueurs ; marks en **pastilles** 0–3 ; points dans l’en-tête joueur ; colonne active + ▶ ; chiffres morts grisés. Styles via `DartsTokens` étendus (pas de couleurs en dur). Pas encore branché sur la saisie live si le shell n’existe pas — peut se développer avec un état de démo / façade mémoire. Voir spec : user stories 12–14 ; Design system.

**Blocked by:** 01

**Status:** ready-for-human

- [ ] Extension `DartsTokens` : marks vides/remplies, chiffre mort, (réutilise activePlayer)
- [ ] Widget matrice lisible à 2–4 joueurs
- [ ] Points dans l’en-tête ; pastilles ; ligne morte grisée
- [ ] Tests widget : joueur actif mis en évidence, marks affichées, points visibles

## Comments

- Peut avancer en parallèle de 02/03 dès que 01 expose un état affichable.
