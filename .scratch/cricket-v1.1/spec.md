# Spec : Cricket en Session (v1.1)

Status: ready-for-agent  
Source: docs/ideas/darts-scoreboard-ui-first.md (grilling 2026-10-03)  
Depends on: v1 X01 Session scorer validated in real soirées before **code** starts  
Vocabulary: **Session** / **Game** / **Visit** / **Mark** / **MPR** — see `CONTEXT.md`.

## Tickets

| # | File | Focus |
|---|---|---|
| 01 | [issues/01-moteur-cricket.md](issues/01-moteur-cricket.md) | Fold / règles / MPR |
| 02 | [issues/02-session-polymorphe-persistance.md](issues/02-session-polymorphe-persistance.md) | Kind + codec + migration |
| 03 | [issues/03-setup-cartes-type-jeu.md](issues/03-setup-cartes-type-jeu.md) | Cartes setup + max 4 |
| 04 | [issues/04-matrice-scoreboard.md](issues/04-matrice-scoreboard.md) | Matrice + tokens |
| 05 | [issues/05-grille-saisie-cricket.md](issues/05-grille-saisie-cricket.md) | Grille D/S/T |
| 06 | [issues/06-ecran-jeu-cricket.md](issues/06-ecran-jeu-cricket.md) | Shell jeu + fin de partie |
| 07 | [issues/07-cycle-session-mixte.md](issues/07-cycle-session-mixte.md) | Rejouer / Changer… |
| 08 | [issues/08-historique-stats-cricket.md](issues/08-historique-stats-cricket.md) | Historique + agrégats |

Order: `01 → 02 → 03 → 06 → 07 → 08` ; `04` après `01` (// `02`/`03`) ; `05` après `01`+`04`.

## Problem Statement

Après la v1, le groupe compte le X01 sans MyDartTraining, mais le Cricket (Standard et Cut-Throat) reste sur MDT. On veut la même Session partagée sur un téléphone, offline, avec une grille de marks lisible et un rythme de saisie au moins aussi bon que MDT — pour ne plus ouvrir MDT du tout.

## Solution

Étendre la **Session** pour enchaîner des parties **X01 ou Cricket**. Au setup, des **cartes** choisissent le type de jeu. Cricket propose Standard ou Cut-Throat (dernier choix mémorisé dans la session). L’écran de jeu est une **matrice** 20→15+Bull × joueurs (marks en pastilles, points dans l’en-tête joueur). Saisie uniquement **fléchette par fléchette** via une grille D/S/T ; fin de visite auto à la 3ᵉ fléchette ; bouton « Fin de tour / no Hit » pour couper. Pas de bannière de tour : colonne active + ▶, avec wakelock et haptique. Undo fléchette par fléchette. « Rejouer » garde la variante et tourne le premier joueur ; le mélange X01 ↔ Cricket passe par « Changer… ». Stats : MPR, points, rounds ; agrégats session séparés par type de jeu.

## User Stories

### Setup et Session
1. As a hôte, I want choisir le type de partie par cartes (X01 | Cricket), so that on pourra en ajouter d’autres plus tard sans refondre le setup.
2. As a hôte, I want choisir Standard ou Cut-Throat au setup Cricket, so that on joue notre variante.
3. As a hôte, I want que le dernier choix Standard/Cut-Throat soit mémorisé dans la session, so that Rejouer / prochain Cricket ne repose pas la question.
4. As a hôte, I want enchaîner X01 et Cricket dans la même Session via « Changer… », so that la soirée reste un seul fil.
5. As a hôte, I want que « Rejouer » après Cricket relance la même variante, mêmes joueurs, premier joueur tourné, so that la partie suivante part en moins de 5 s.
6. As a hôte, I want un refus clair si j’essaie Cricket avec plus de 4 joueurs, so that la matrice reste lisible.
7. As a hôte, I want que X01 reste plafonné à 8 joueurs, so that le comportement v1 ne régresse pas.
8. As a hôte, I want reprendre une Session avec une partie Cricket en cours après kill de l’app, so that le journal reste la source de vérité.
9. As a hôte, I want terminer la Session explicitement après une partie Cricket, so that elle passe à l’historique comme en X01.

### Saisie
10. As a joueur, I want une grille 20→Bull × D/S/T (Bull : DBull / Bull), so that je saisis un mark en un tap.
11. As a joueur, I want que la 3ᵉ fléchette termine la visite automatiquement, so that je ne confirme pas.
12. As a joueur, I want « Fin de tour » / « no Hit » pour passer avant 3 fléchettes, so that un tour vide coûte un tap.
13. As a joueur, I want qu’un tap sur un chiffre mort soit no-op (ligne grisée, haptique léger ok), so that je ne casse pas l’état.
14. As a joueur, I want un undo fléchette par fléchette (y compris annuler un Fin de tour), so that le modèle mental reste celui du X01.
15. As a joueur, I want qu’un hors-Cricket (1–14, miss hors cible) compte 0 mark et consomme une fléchette, so that le rythme de visite reste correct.
16. As a joueur, I want que outer bull (25) = 1 mark et inner (50) = 2 marks, so that les règles bull sont respectées.

### Scoreboard
17. As a joueur, I want une matrice marks (lignes = chiffres, colonnes = joueurs) avec pastilles 0–3, so that l’état se lit d’un coup.
18. As a joueur, I want les points dans l’en-tête de chaque joueur, so that le standing est visible sans ligne dédiée.
19. As a joueur, I want la colonne active mise en évidence et un ▶ sur le nom, so that on sait qui joue sans bannière plein écran.
20. As a joueur, I want wakelock + haptique au changement de joueur (pas de bannière texte), so that le téléphone posé reste utilisable.
21. As a joueur, I want lire les marks à ~2–3 m sur un téléphone posé, so that on n’a pas à se pencher à chaque volée.

### Règles Standard
22. As a joueur, I want fermer un chiffre à 3 marks (S/D/T = 1/2/3), so that la progression est claire.
23. As a joueur, I want que les marks en trop sur un chiffre fermé par moi marquent des points (valeur × multiplicateur) tant qu’un adversaire ne l’a pas fermé, so that le scoring Standard est correct.
24. As a joueur, I want qu’un chiffre fermé par tous soit mort (plus de points), so that on ne score plus dessus.
25. As a joueur, I want gagner dès que j’ai tout fermé et un score ≥ tous les adversaires, so that la fin de partie est automatique.
26. As a joueur, I want continuer à scorer si j’ai tout fermé mais moins de points qu’un adversaire, so that je peux encore remonter.

### Règles Cut-Throat
27. As a hôte, I want jouer Cut-Throat à 2 joueurs, so that la variante reste disponible en duo.
28. As a joueur, I want que les points marqués sur un chiffre fermé par moi s’ajoutent aux adversaires encore ouverts sur ce chiffre, so that le scoring Cut-Throat est correct.
29. As a joueur, I want gagner dès que j’ai tout fermé avec le score le plus bas (ou égal au plus bas), so that la fin de partie Cut-Throat est automatique.

### Sudden death
30. As a joueur, I want qu’si le board est mort pour tous et les scores sont égaux, le premier Bull (outer ou inner) gagne, so that les égalités se résolvent sans arbitre.

### Fin de partie et historique
31. As a hôte, I want l’écran de fin (gagnant, MPR, points, rounds, Rejouer / Changer… / Terminer) comme en X01, so that la chorégraphie de soirée est unique.
32. As a joueur, I want une ligne d’historique `CRICKET (Standard|Cut-Throat) — gagnant — MPR…`, so that on relit la soirée.
33. As a joueur, I want au détail de Session des agrégats séparés X01 (moyenne 3D) et Cricket (MPR), seulement pour les joueurs qui ont joué ce type, so that un mix ne mélange pas les métriques.
34. As a joueur, I want voir mon MPR de partie (= marks / visites), so that je compare mon rythme Cricket.

## Implementation Decisions

- **Gate produit** : aucun code Cricket tant que 2 soirées X01 n’ont pas validé « on garde ça ».
- **Seam principal (domaine)** : étendre le journal Session — config de partie discriminée et fold par kind. Un seul modèle Session ; pas de second repository.
- **Config** : type scellé `GameConfig` (`X01Config` | `CricketConfig`). `CricketConfig` porte la variante (`standard` | `cutThroat`). `GameStarted` porte `GameConfig` au lieu de `X01Config` seul.
- **État** : état de partie discriminé (X01 vs Cricket) exposé via la façade Session existante (`startGame` / commandes / undo). Les écrans lisent un état Cricket (marks par joueur×chiffre, points, visite en cours, winner, sudden-death) sans recalculer les règles.
- **Événements** : réutiliser `DartThrown` pour chaque fléchette Cricket. Ajouter un événement explicite **`VisitEnded`** pour « Fin de tour / no Hit » (visite courte sans inventer des miss synthétiques). Undo = retirer le dernier événement de visite (`DartThrown` ou `VisitEnded`) comme aujourd’hui pour X01.
- **Hors-Cricket** : un `Dart` hors 15–20/Bull appliqué en Cricket → 0 mark, consomme la fléchette ; pas de variante no-slop.
- **Board mort / sudden death** : quand tous les joueurs ont fermé tous les chiffres et les points sont égaux, la partie entre en sudden death ; le prochain Bull (25 ou 50) gagne.
- **Persistance** : `game_started` payload versionné avec un discriminant `kind` (`x01` | `cricket`). Anciens journaux sans `kind` = X01 (compat). Nouveau type d’event `visit_ended`. Migration Drift / rewrite codec si besoin ; tests de migration obligatoires (pattern existant).
- **Setup** : cartes de type de jeu (extensibles). Cricket : 1–4 joueurs ; refus explicite si >4 (pas de trim silencieux). Mémoriser la dernière variante Cricket **dans l’état de session** (pas un pref global).
- **UI jeu** : scoreboard matrice + grille D/S/T ; pas de `TurnBanner` texte (X01 le garde). Tokens marks (vide / 1 / 2 / 3 / mort / colonne active) via `DartsTokens` — pas de couleurs hardcodées.
- **Rematch** : même `CricketConfig` + rotation du premier joueur. Changement X01 ↔ Cricket uniquement via le flux « Changer… » (setup cartes).
- **Historique** : formatage dédié Cricket ; agrégats session filtrés par kind de partie.

## Testing Decisions

- Tester le **comportement externe** de la façade Session / fold (marks, points, mort, win, sudden death, undo, MPR) — pas les widgets internes de pastilles.
- **Modules** : moteur Cricket (ticket 01), codec + migration (02), setup cartes / plafond 4 (03), widgets matrice + grille + shell (04–06), cycle mixte (07), historique/agrégats (08).
- **Prior art** : `test/session/*` (fold, undo, resume), `test/storage/migration_test.dart`, `test/game/game_screen_test.dart`, `test/setup/setup_screen_test.dart`, `test/history/*`.
- Façade d’abord (Dart pur, sans Flutter/Drift) ; puis widget smoke pour refus >4, highlight colonne, Changer… X01↔Cricket, ligne historique.
- Les tests X01 existants restent verts (régression non négociable).

## Out of Scope

- Affichage marks `/ X O` ou toggle de glyphes (réévalué en v1.4 si douleur soirée).
- Vue whiteboard 2 joueurs, no-slop, chiffres custom, handicap, points off.
- Saisie total / quick-scores en Cricket.
- Bannière de tour texte.
- Sets/legs, bots, sync, cible cliquable, i18n, paysage (v1.3), Killer/Shanghai (v1.2).

## Further Notes

- Règles validées contre darts.org / Wikipedia / usages pub (grilling + research).
- Succès produit : plus besoin de MDT pour le Cricket.
- Tickets déjà découpés sous `issues/` ; respecter l’ordre et le gate X01 sur le ticket 01.
