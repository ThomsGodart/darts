# 08: Joueurs + setup de soirée

**What to build:** On gère un catalogue local de joueurs : création avec juste un nom, renommage, suppression si le joueur n’a jamais joué, archivage sinon. Démarrer une soirée consiste à choisir 1 à 8 joueurs (les existants en tête de liste), 501 ou 301 et Double-out ou non, à réordonner les joueurs, puis à lancer la première partie. Objectif : première partie lancée en moins de 30 s depuis l’ouverture de l’app. Les deux joueurs fixes du ticket 02 disparaissent. Voir spec : Joueurs, user stories 1–10.

**Blocked by:** 03 (Règles Double-out complètes), 07 (Persistance drift + reprise).

**Status:** ready-for-agent

- [x] Joueurs persistés (table joueurs drift : id, nom, archivé)
- [x] Un joueur référencé par une partie est archivé, jamais supprimé physiquement
- [x] Tests de façade : créer une soirée avec joueurs, ordre et config → la première partie respecte l’ordre et la config
- [x] Écran de setup : sélection des joueurs (1–8), création inline, 501/301, Double-out on/off, réordonnancement
- [ ] Parcours accueil → partie lancée en moins de 30 s, chronométré à la main (à faire sur appareil)

## Comments

- 2026-10-03 — Implémenté :
  - Port `PlayerCatalog` (active / archived / nameProblem / add / rename / remove / markPlayed) en mémoire et en drift, avec un contrat de tests commun.
  - Table `players` (id, name, archived, hasPlayed), schéma v2 avec migration testée depuis une base v1.
  - Un joueur est marqué « a joué » quand une partie démarre avec lui. `remove` l’archive s’il a joué, et le supprime sinon.
  - Noms : non vides, uniques parmi les actifs sans tenir compte de la casse ; un nom archivé est réutilisable.
  - Façade : au plus 8 joueurs, pas de doublon.
  - Écran « Nouvelle soirée » :
    - joueurs existants cochables, l’ordre de jeu suit l’ordre des coches ;
    - ajout inline (le joueur ajouté est coché), renommer / supprimer via menu ;
    - liste « Ordre de jeu » réordonnable ;
    - 501/301 et Double-out.
  - « Nouvelle partie 501 » et les joueurs fixes ont disparu.
- 2026-10-03 — Suite à la code review :
  - « A joué » est posé seulement après un démarrage de partie accepté.
  - Vérification du nom et écriture dans une même transaction drift : deux taps rapides ne créent pas de doublon.
  - Ids lus sans crash, suppression idempotente.
  - Le contrôleur de setup est créé et libéré par l’accueil, et ne notifie plus après fermeture.
  - Confirmation avant « Supprimer » (avec mention de l’archivage).
  - Les helpers du catalogue ne sont plus exportés par la librairie `soiree`.
