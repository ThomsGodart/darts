# Spec : Cricket Standard + Cut-Throat (v1.1)

Status: ready-for-agent
Source: docs/ideas/darts-scoreboard-ui-first.md (v1.1), .scratch/x01-soiree/spec.md
Vocabulaire : `CONTEXT.md` (code en anglais, UI en français ; le groupe de parties est une **Session**).

## Problem Statement

Le groupe joue aussi au Cricket, surtout en Cut-Throat. Pendant la v1, on gardait MyDartTraining pour ça : il faut donc changer d’app au milieu d’une session. Tant que le Cricket n’est pas dans l’app, le critère de succès « on n’ouvre plus MyDartTraining » n’est pas atteint.

## Solution

Le Cricket (Standard et Cut-Throat) devient un type de partie de la **Session**, à côté du X01. Une même session enchaîne des parties de types différents : un 501, puis un Cut-Throat avec les mêmes joueurs. « Rejouer » garde le type de partie, et « Changer… » permet d’en changer. La saisie se fait fléchette par fléchette, avec le sélecteur existant. L’écran de jeu montre une grille de marques lisible de loin : chiffres 15–20 et Bull, marques de chaque joueur, chiffres fermés, points. La stat affichée est le **MPR** (marques par volée), par partie et par session, et l’historique la reprend.

## User Stories

### Démarrer
1. As a hôte, I want choisir le type de partie (X01 ou Cricket) dans le setup, so that on lance un Cricket aussi vite qu’un 501.
2. As a hôte, I want choisir Cricket Standard ou Cut-Throat, so that on joue notre variante habituelle.
3. As a hôte, I want que « Rejouer » relance le même type et la même variante, avec la rotation du premier joueur, so that on enchaîne sans reconfigurer.
4. As a hôte, I want passer d’un X01 à un Cricket (et inversement) via « Changer… », so that une session mélange les jeux.

### Saisie
5. As a joueur, I want saisir chaque fléchette (secteur 1–20, simple/double/triple, 25, Bull, raté), so that les marques sont exactes.
6. As a joueur, I want qu’une fléchette hors 15–20 et Bull compte comme lancée sans marque, so that je n’ai pas à la traduire en « raté ».
7. As a joueur, I want que la volée se termine seule à la 3e fléchette ou quand la partie est gagnée, so that je n’ai rien à confirmer.
8. As a joueur, I want annuler fléchette par fléchette, y compris sur les volées précédentes et après la victoire, so that une erreur se corrige comme en X01.
9. As a joueur, I want que la saisie par total ne soit pas proposée en Cricket, so that je ne saisis rien d’ambigu.

### Règles
10. As a joueur, I want qu’un simple vaille 1 marque, un double 2, un triple 3, le 25 une marque de Bull et le Bull deux, so that le comptage suit les règles.
11. As a joueur, I want qu’un chiffre soit fermé pour moi à 3 marques, so that je vois ma progression.
12. As a joueur (Standard), I want que mes marques au-delà de 3 sur un chiffre que j’ai fermé me rapportent sa valeur en points tant qu’au moins un adversaire ne l’a pas fermé, so that je peux scorer.
13. As a joueur (Cut-Throat), I want que ces marques en trop donnent les points à chaque adversaire qui n’a pas fermé le chiffre, so that la variante Cut-Throat est respectée.
14. As a joueur, I want qu’un chiffre fermé par tout le monde ne rapporte plus rien, so that il est « mort ».
15. As a joueur (Standard), I want gagner dès que j’ai tout fermé et que j’ai au moins autant de points que chaque adversaire, so that la règle de victoire est appliquée.
16. As a joueur (Cut-Throat), I want gagner dès que j’ai tout fermé et que j’ai au plus autant de points que chaque adversaire, so that la règle inverse est appliquée.
17. As a joueur, I want que le Bull vaille 25 points par marque en trop, so that il compte comme un chiffre.

### Lisibilité
18. As a joueur qui attend, I want une grille avec une ligne par chiffre (20 en haut, Bull en bas) et une colonne par joueur, avec des marques /, X, Ⓧ, so that je lis l’état de loin.
19. As a joueur, I want que la colonne du joueur actif soit mise en avant et que les chiffres morts soient grisés, so that je sais quoi viser.
20. As a joueur, I want voir les points de chacun en gros sous la grille, so that je sais qui mène.
21. As a joueur, I want voir les fléchettes de la volée en cours, so that je vérifie ma saisie.

### Stats et historique
22. As a joueur, I want voir mon MPR de la partie en cours et en fin de partie, so that je suis ma forme.
23. As a joueur, I want voir mon MPR sur la session (parties de Cricket seulement), à côté de ma moyenne X01 (parties X01 seulement), so that les deux stats ne se mélangent pas.
24. As a joueur, I want que l’historique indique le type de chaque partie (« 501 DO », « Cricket », « Cut-Throat ») et la bonne stat, so that le détail d’une session reste lisible.

### Fiabilité
25. As a joueur, I want qu’une partie de Cricket interrompue reprenne exactement où elle en était, so that on ne perd rien.
26. As a joueur, I want que les sessions enregistrées avant la v1.1 restent lisibles, so that l’historique n’est pas perdu.

## Implementation Decisions

- **Un seul module profond : la façade `Session`.** Le Cricket y entre par les mêmes commandes et le même journal, sans façade parallèle.
- **Configuration de partie.** `GameStarted` porte une `GameConfig` scellée : `X01Config` (existant) ou `CricketConfig(variant: standard | cutThroat)`. `Session.startGame` et `rematch` acceptent n’importe quelle `GameConfig`. Rejouer garde le type ; « Changer… » passe par le setup, qui propose le type.
- **État de partie.** Le `GameState` actuel est spécifique au X01. Il est découpé en une partie commune (joueurs, ordre, joueur actif, fléchettes de la volée en cours, gagnant, volées jouées) et un état propre au type : restes, visites et checkout pour X01 ; marques par chiffre et points pour Cricket. Ce découpage se fait **avant** le Cricket et sans aucun changement de comportement (prefactor), sous les tests existants.
- **Événements.** Aucun nouveau type d’événement : le Cricket utilise `GameStarted`, `DartThrown` et `SessionEnded`. `VisitTotalSubmitted` est refusé pour une partie de Cricket (résultat typé). L’undo reste « retirer le dernier événement de saisie et recalculer ».
- **Codec.** `game_started` gagne un champ `kind` (`x01` | `cricket`) et, pour le Cricket, `variant`. Un `game_started` sans `kind` est lu comme X01 : les journaux existants restent valides **sans migration de base**.
- **Moteur Cricket.** Fonctions pures dans le fold :
  - marques d’une fléchette : 15–20 et Bull uniquement, multiplicateur = nombre de marques, 25 = 1 marque de Bull, Bull = 2 ;
  - fermeture à 3 marques ;
  - répartition des marques en trop selon la variante ;
  - test de victoire après chaque fléchette.
  - Un chiffre fermé par tous les joueurs ne rapporte plus rien. Une volée compte 3 fléchettes, ou moins si la partie est gagnée avant.
- **MPR.** Marques sur 15–20 et Bull (celles qui ferment comme celles qui scorent, mortes comprises) ÷ volées jouées. La volée gagnante compte pour une volée entière. Par partie et par session, calculé uniquement sur les parties de Cricket. La moyenne 3 fléchettes reste calculée sur les seules parties X01.
- **UI.**
  - Le setup gagne un choix « X01 / Cricket », puis les options du type choisi (501/301 et Double-out, ou Standard/Cut-Throat).
  - L’écran de jeu choisit son scoreboard selon le type : grille Cricket ou scoreboard X01.
  - En Cricket, le tiroir de saisie n’affiche que le sélecteur de fléchettes (pas de total, pas de quick-scores).
  - Nouveaux tokens de thème pour la grille : marque, chiffre fermé, chiffre mort, taille des marques et des points.
- **Persistance.** Le schéma drift ne change pas. Les sessions mixtes passent par le même journal.

## Testing Decisions

- **Un seul seam : la façade `Session`**, comme pour le X01. Les tests envoient des commandes (`startGame` avec une `CricketConfig`, `throwDart`, `undo`, `rematch`, `endSession`) et vérifient l’état exposé (marques, chiffres fermés et morts, points, joueur actif, gagnant, MPR). Ils ne testent jamais le fold ni le codec directement.
- **Couverture attendue :**
  - valeur en marques de chaque fléchette (dont 25, Bull, secteurs 1–14, raté) ;
  - fermeture, points en Standard, points en Cut-Throat, chiffres morts ;
  - victoire Standard (égalité de points comprise), victoire Cut-Throat, partie qui ne se termine pas tant qu’un chiffre reste ouvert ;
  - fin de volée à la 3e fléchette ou à la victoire ;
  - undo sur plusieurs volées et après la victoire ;
  - refus de la saisie par total ;
  - MPR par partie et par session ; session mixte X01 + Cricket (chaque stat sur ses parties) ;
  - Rejouer qui garde la variante et fait tourner le premier joueur.
- **Persistance :** le contrat de repository rejoue une session mixte après relance. Un test de codec passe par le repository : un journal de la v1 (sans `kind`) se relit à l’identique.
- **Prefactor :** les tests X01 existants passent sans modification ; c’est la preuve que le découpage de `GameState` ne change rien.
- **Widgets :** uniquement le comportement purement UI (choix du type dans le setup, grille affichée pour une partie de Cricket, pas de pavé de total en Cricket). Aucune règle de Cricket au niveau widget.

## Out of Scope

- Variantes au-delà de Standard et Cut-Throat : No-Score, Random Cricket, Tactics (10–20), Hidden Cricket.
- Limite de tours (« 20 rounds ») et départage au nombre de tours.
- Cricket en équipes.
- Stats Cricket avancées (marques par chiffre, % de fermeture, « White Horse »).
- Saisie par marques de volée (« 5 marques ») au lieu de fléchette par fléchette.
- Killer, Shanghai, Halve-It et les autres jeux.

## Further Notes

- La rotation du premier joueur, la fin de session, la reprise et l’historique sont déjà génériques : le Cricket les obtient par la façade, sans code dédié, une fois le prefactor fait.
- Une fléchette hors 15–20 et Bull reste enregistrée telle quelle (secteur et multiplicateur) : rien n’est perdu si l’on ajoute plus tard des variantes avec d’autres chiffres.
- Pour la grille à distance, le même test que pour le X01 s’applique : un écran statique, lu à 2–3 m sur un 6", avant tout polish.
