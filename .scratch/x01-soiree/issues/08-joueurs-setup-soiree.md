# 08: Joueurs + setup de soirée

**What to build:** On gère un catalogue local de joueurs : création avec juste un nom, renommage, suppression si le joueur n’a jamais joué, archivage sinon. Démarrer une soirée consiste à choisir 1 à 8 joueurs (les existants en tête de liste), 501 ou 301 et Double-out ou non, à réordonner les joueurs, puis à lancer la première partie. Objectif : première partie lancée en moins de 30 s depuis l’ouverture de l’app. Les deux joueurs fixes du ticket 02 disparaissent. Voir spec : Joueurs, user stories 1–10.

**Blocked by:** 03 (Règles Double-out complètes), 07 (Persistance drift + reprise).

**Status:** ready-for-agent

- [ ] Joueurs persistés (table joueurs drift : id, nom, archivé)
- [ ] Un joueur référencé par une partie est archivé, jamais supprimé physiquement
- [ ] Tests de façade : créer une soirée avec joueurs, ordre et config → la première partie respecte l’ordre et la config
- [ ] Écran de setup : sélection des joueurs (1–8), création inline, 501/301, Double-out on/off, réordonnancement
- [ ] Parcours accueil → partie lancée en moins de 30 s, chronométré à la main
