# Darts Points Counter — Scorer X01 de soirée

## Problem Statement
How might we faire tourner une soirée fléchettes entre potes sur **un seul téléphone partagé**, avec une saisie X01 plus rapide et plus lisible que MyDartTraining, sans jamais dépendre du réseau ?

## Recommended Direction
**Direction A — Scorer X01 de soirée.** La douleur réelle est en X01 (le Cricket de MyDartTraining est jugé correct) : pubs qui coupent le rythme, trop de taps par volée, UI illisible de loin. La v1 attaque uniquement ça. Cricket (Standard + Cut-Throat) arrive en v1.1 ; pendant les soirées de test, on garde MDT pour le Cricket.

L’écran de jeu est un **scoreboard d’abord** : joueur actif et reste en très gros, lisibles à 2–3 m sur un téléphone posé ; le keypad est un tiroir compact en bas. Saisie par **total de volée** avec une rangée de quick-scores (26, 41, 45, 60, 81, 85, 100, 140, 180) et suggestion de checkout ≤ 170 ; le mode **fléchette par fléchette** est disponible au choix. Pas de confirmation : on saisit, le tour passe, un **undo multi-niveaux** toujours visible rattrape les erreurs (le cas normal sur un téléphone qu’on se passe).

Le concept central est la **soirée** : mêmes joueurs, parties enchaînées par « Rejouer » en un tap (ordre de départ tourné), historique groupé par soirée avec la moyenne 3 fléchettes de chacun. Local-first ; Supabase (déjà initialisé dans `lib/main.dart`) reste réservé à une sync future, non bloquante.

Succès à 3 mois : on n’ouvre plus MyDartTraining (X01 dès la v1, Cricket à la v1.1).

## Key Assumptions to Validate
- [ ] **La saisie bat MDT** — ≤ 2 taps en moyenne par volée en mode total ; mesurer sur une soirée (compteur de taps en debug).
- [ ] **Lisible de loin** — reste et nom du joueur actif lisibles à 2–3 m sur un écran 6" ; prototype statique testé contre la cible avant tout polish.
- [ ] **No-confirm + undo suffit** — sur 2 soirées, aucune erreur restée non corrigée ; noter chaque undo.
- [ ] **Offline total** — cold start en mode avion OK (vérifier que `Supabase.initialize` ne bloque pas `runApp`), soirée complète sans réseau.
- [ ] **Setup < 30 s** pour la 1re partie, **< 5 s** pour « Rejouer ».
- [ ] **2 soirées sans MDT pour le X01** → feedback « on garde ça ».

## MVP Scope
**In (v1)**
- Joueurs locaux (CRUD minimal : nom)
- X01 : 501 et 301, Straight-in, Double-out ; un leg par partie
- Saisie mixte : total de volée (+ quick-scores) ou fléchette par fléchette, commutable en cours de partie
- Au finish en mode total : « combien de fléchettes ? » (pour une moyenne exacte) ; bust détecté automatiquement
- Suggestion de checkout (table statique 2–170, double-out)
- Écran scoreboard-first + tiroir keypad ; bannière + haptique au changement de joueur ; undo multi-niveaux
- Soirée : regroupement des parties, « Rejouer » en 1 tap avec rotation du premier joueur
- Historique local par soirée (parties finies + reprise de partie en cours)
- Stat unique : moyenne 3 fléchettes par joueur (par partie et par soirée)
- Fondations d’archi (voir plus bas) : tokens de thème + thème `default`, abstraction d’input de score

**v1.1**
- Cricket Standard + Cut-Throat (15–20 + Bull), saisie fléchette par fléchette (marks)

## Not Doing (and Why)
- **Cricket en v1** — MDT le fait correctement ; doublerait l’UI (grille de marks = autre écran) avant d’avoir validé la saisie X01.
- **Sets/legs (First-to / Best-of)** — le groupe joue des legs simples ; la soirée + « Rejouer » couvre le besoin.
- **701, Double-in** — pas joués par le groupe.
- **Stats au-delà de la moyenne** (% victoires, % checkout, classements) — personne ne les regardera ; le % checkout exigerait en plus de compter les fléchettes tentées sur double.
- **Sync cloud / comptes** — un seul téléphone partagé, aucun besoin multi-device en v1.
- **Saisie vocale** — piste forte post-v1 (mains pleines, téléphone loin) ; l’abstraction d’input la rend possible sans refactor.
- **Cible cliquable** — en pratique un keypad plus lent ; post-v1, prototype de hit-test avant d’engager.
- **Killer, Halve-It, Shanghai, Golf, bots, career, pubs, shop** — hors du problème.
- **Thèmes pro / fléchettes personnalisables** — post-v1, préparés par les tokens.

## Design system & extensibilité (contraintes d’archi, pas scope v1 produit)

### Thèmes
- Tout le styling passe par des **tokens** (couleurs, surfaces, accents score, typo, rayons…) — pas de couleurs hardcodées dans les écrans.
- Catalogue de thèmes identifiés par un **id string** ; le premier s’appelle **`default`**.
- `ThemeExtension` app-specific en plus du `ColorScheme` Material : joueur actif, bust, checkout possible, (plus tard) marks Cricket et couleurs de cible.
- Typo du scoreboard pensée pour la lecture à distance (tailles en tokens, pas en dur).

### Saisie des points
- Le moteur de règles consomme des **événements de volée**, indépendants de l’UI. Une volée est soit :
  - **par fléchettes** : liste de 1–3 hits (secteur, simple/double/triple, bull/outer), soit
  - **par total** : score + nombre de fléchettes utilisées (3 par défaut, demandé seulement au finish).
- Le moteur X01 accepte les deux formes ; la moyenne 3 fléchettes = points / fléchettes × 3. Le Cricket (v1.1) n’accepte que la forme par fléchettes.
- v1 : keypad (total + quick-scores) et sélecteur par fléchette. Plus tard : voix, cible cliquable — mêmes événements.
- Undo = retirer le dernier événement et rejouer l’état ; pas de logique d’annulation spécifique par écran.

## Open Questions
- Stockage local : drift (SQLite) vs Isar — penche pour drift (maintenance active, requêtes historique/soirée naturelles en SQL) ; à trancher au premier ticket data.
- Orientation : le téléphone posé incite au paysage — portrait seul en v1, ou paysage dès la v1 ?
- Mode fléchette par fléchette : réglage par joueur, ou bascule ponctuelle par volée ?
- FR only v1 ou i18n dès le départ ?
- Thèmes pro : liés au profil joueur, au thème app global, ou les deux ?

## Context (idéation)
- Concurrentes : Compteur de Fléchettes (setup clair, peu de modes) ; MyDartTraining (profondeur, UI datée, pubs, trop de taps en X01 ; Cricket jugé correct).
- Usage réel : un téléphone partagé, legs simples, Cut-Throat comme variante Cricket jouée ; stats = moyenne 3 fléchettes ou rien.
- Guide règles source : `guide_exhaustif_des_types_de_jeux_de_fléchettes…` — X01/Cricket OK vs web.
- Directions écartées : parité MDT en v1 (X01 + Cricket, double le temps avant le premier test) ; soirée-first avec saisie minimale (traite la mauvaise douleur) ; engine-first catalogue ; companion TV/2e écran (v1.5+).
