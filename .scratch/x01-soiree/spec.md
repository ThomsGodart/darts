# Spec : Scorer X01 de soirée (v1)

Status: ready-for-agent
Source: docs/ideas/darts-scoreboard-ui-first.md

## Problem Statement

Entre potes, on compte nos parties de X01 sur MyDartTraining, qui nous casse la soirée : des pubs coupent le rythme, il faut trop de taps par volée, et l’UI est datée et illisible de loin. On utilise un seul téléphone qu’on se passe ou qu’on pose près de la cible. Personne ne regarde les stats au-delà de la moyenne. On veut une app qui compte un 501 plus vite et plus lisiblement que MDT, même sans réseau, et qui enchaîne les parties de la soirée sans tout reconfigurer.

## Solution

Une app Flutter local-first organisée autour de la **Soirée** : un groupe de joueurs qui enchaîne des **parties** X01 (501 ou 301, Straight-in, Double-out, un leg). L’écran de jeu affiche d’abord le scoreboard : le joueur actif et son reste en très gros, lisibles à 2–3 m. Le keypad est un tiroir compact en bas. Une volée se saisit en un tap avec un quick-score, ou en tapant son total. Un mode fléchette par fléchette peut s’activer pour une volée donnée. Il n’y a pas de confirmation : le tour passe aussitôt, et un undo multi-niveaux reste toujours visible. Le bust est détecté automatiquement. Une suggestion de checkout s’affiche quand le reste est ≤ 170. En fin de partie, « Rejouer » relance la même configuration en un tap, avec rotation du premier joueur. L’historique est groupé par soirée et montre la moyenne 3 fléchettes de chacun. Tout fonctionne en mode avion.

## User Stories

### Joueurs
1. As a joueur, I want créer un joueur juste avec un nom, so that l’ajouter prend quelques secondes.
2. As a joueur, I want renommer un joueur, so that je peux corriger une faute de frappe.
3. As a joueur, I want supprimer un joueur qui n’a jamais joué, so that la liste reste propre.
4. As a joueur, I want qu’un joueur ayant déjà joué soit archivé plutôt que supprimé, so that l’historique reste cohérent.
5. As a joueur, I want retrouver les joueurs existants en tête de liste au setup, so that je n’ai pas à les recréer à chaque soirée.

### Soirée et setup
6. As a hôte, I want démarrer une soirée en choisissant 1 à 8 joueurs, so that le groupe est défini une seule fois.
7. As a hôte, I want choisir 501 ou 301, so that on joue notre format habituel.
8. As a hôte, I want que Double-out soit activé par défaut et désactivable (Straight-out), so that on peut jouer plus détendu.
9. As a hôte, I want réordonner les joueurs avant la première partie, so that l’ordre de jeu est celui du groupe.
10. As a hôte, I want lancer la première partie en moins de 30 s depuis l’ouverture de l’app, so that la soirée démarre sans friction.
11. As a hôte, I want ajouter un joueur arrivé en retard entre deux parties, so that il rejoint la soirée sans en recréer une.
12. As a hôte, I want retirer un joueur parti entre deux parties, so that les suivantes ne l’attendent pas.
13. As a hôte, I want terminer la soirée explicitement, so that elle passe dans l’historique.

### Saisie d’une volée
14. As a joueur, I want saisir ma volée en un tap avec un quick-score (26, 41, 45, 60, 81, 85, 100, 140, 180), so that les volées courantes vont vite.
15. As a joueur, I want taper un total de 0 à 180 puis valider, so that toute volée est saisissable.
16. As a joueur, I want qu’un total impossible (ex. 179, 163) soit refusé, so that une faute de frappe ne fausse pas la partie.
17. As a joueur, I want un bouton « 0 / raté » direct, so that une volée vide se saisit en un tap.
18. As a joueur, I want basculer cette volée en mode fléchette par fléchette (secteur 1–20, simple/double/triple, outer bull 25, bull 50, raté), so that je peux saisir précisément quand je le souhaite.
19. As a joueur, I want qu’en mode fléchettes la volée se termine automatiquement à la 3e fléchette, au bust ou au checkout, so that je n’ai rien à confirmer.
20. As a joueur, I want que le tour passe au joueur suivant sans confirmation, so that le rythme ne se casse pas.
21. As a joueur, I want qu’une bannière avec le nom du joueur suivant et une vibration marquent le changement de tour, so that celui qui prend le téléphone sait que c’est à lui.

### Règles X01
22. As a joueur, I want que mon reste diminue du score de la volée, so that je suis où j’en suis.
23. As a joueur, I want qu’une volée qui ferait passer mon reste sous 0, à 1 (en Double-out) ou à 0 sans finir sur un double (en Double-out) soit un bust, so that les règles officielles sont respectées.
24. As a joueur, I want qu’un bust remette mon reste à sa valeur de début de volée et passe le tour, so that la règle est appliquée sans calcul de tête.
25. As a joueur, I want qu’un bust soit clairement signalé à l’écran, so that tout le monde le voit.
26. As a joueur, I want qu’en mode total, quand ma volée amène le reste exactement à 0, l’app me demande « combien de fléchettes ? » (1, 2 ou 3), so that ma moyenne reste exacte.
27. As a joueur, I want qu’en mode total, l’app me demande « fini sur un double ? » si mon checkout n’est pas faisable autrement qu’en finissant hors double, so that le Double-out est respecté. Alternative acceptée : le checkout en mode total est présumé valide si le score est atteignable en finissant sur un double.
28. As a joueur, I want qu’un checkout impossible en Double-out (ex. reste 169, 168, 166, 165, 163, 162, 159, ou supérieur à 170) ne puisse pas être saisi comme fin de partie, so that l’état reste valide.
29. As a joueur, I want que la partie se termine dès qu’un joueur atteint 0 valablement, so that le gagnant est désigné immédiatement.

### Scoreboard et lisibilité
30. As a joueur qui attend, I want voir de loin le nom du joueur actif et son reste en très grande taille, so that je suis la partie sans m’approcher.
31. As a joueur, I want voir le reste de tous les joueurs, so that je sais qui mène.
32. As a joueur, I want voir le score de la dernière volée de chaque joueur, so that on peut vérifier une saisie.
33. As a joueur, I want voir une suggestion de checkout quand mon reste est ≤ 170 et finissable, so that je sais quoi viser.
34. As a joueur, I want que la suggestion se mette à jour fléchette par fléchette en mode fléchettes, so that elle reste pertinente en cours de volée.
35. As a joueur, I want voir ma moyenne 3 fléchettes de la partie en cours, so that je suis ma forme.

### Undo et corrections
36. As a joueur, I want un undo toujours visible qui annule la dernière saisie (volée ou fléchette), so that je corrige une erreur en un tap.
37. As a joueur, I want pouvoir annuler plusieurs saisies d’affilée, y compris sur les volées des autres joueurs, so that on rattrape une erreur repérée en retard.
38. As a joueur, I want qu’un undo après la fin de partie rouvre la partie, so that un checkout mal saisi se corrige.
39. As a joueur, I want qu’après un undo le tour revienne au bon joueur, so that l’ordre reste correct.

### Rejouer et enchaînement
40. As a hôte, I want un écran de fin de partie montrant le gagnant et la moyenne de chacun, so that on célèbre le vainqueur.
41. As a hôte, I want « Rejouer » en un tap pour relancer la même configuration, so that la partie suivante démarre en moins de 5 s.
42. As a hôte, I want que le premier joueur tourne à chaque nouvelle partie, so that personne n’a toujours l’avantage.
43. As a hôte, I want pouvoir changer 501/301 ou le Double-out avant de rejouer, so that on varie sans recréer la soirée.

### Reprise et historique
44. As a joueur, I want qu’une partie interrompue (app tuée, téléphone verrouillé, crash) reprenne exactement où elle en était, so that on ne perd rien.
45. As a joueur, I want qu’à l’ouverture l’app propose de reprendre la soirée en cours, so that on reprend sans chercher.
46. As a joueur, I want consulter la liste des soirées passées (date, joueurs, nombre de parties), so that on se souvient de nos soirées.
47. As a joueur, I want voir le détail d’une soirée : chaque partie avec son gagnant et la moyenne 3 fléchettes par joueur, plus la moyenne de chacun sur la soirée, so that on compare nos performances.
48. As a joueur, I want supprimer une soirée de l’historique, so that je retire une soirée de test.

### Offline et fiabilité
49. As a joueur, I want que l’app démarre et fonctionne complètement en mode avion, so that une soirée sans réseau ne pose aucun problème.
50. As a joueur, I want qu’aucune pub ni popup n’interrompe la partie, so that le rythme est préservé.
51. As a joueur, I want que l’écran ne se mette pas en veille pendant une partie, so that le scoreboard reste visible.

### Fondations (pour les développeurs)
52. As a développeur, I want que tout le style passe par des tokens de thème avec un thème `default`, so that d’autres thèmes s’ajoutent plus tard sans refactor.
53. As a développeur, I want que le moteur consomme des événements de volée indépendants de l’UI, so that une saisie vocale ou une cible cliquable pourra émettre les mêmes événements.

## Implementation Decisions

- **Façade `Soirée` (module profond, Dart pur, sans Flutter ni DB).** C’est le seul point d’entrée de la logique métier.
  - Commandes (*amendé le 2026-10-03*) : démarrer une partie (première de la soirée, ou suivante avec des joueurs ajoutés, retirés ou réordonnés) ; soumettre une volée par total (score, et nombre de fléchettes seulement au checkout) ; soumettre une fléchette (secteur + multiplicateur, ou bull/outer/raté) ; undo ; rejouer (rotation, config éventuellement modifiée) ; terminer la soirée (entre deux parties, ou en abandonnant une partie en cours quand on en commence une nouvelle).
  - Lecture : un état immuable (`SoiréeState`) qui contient la partie courante (joueurs, ordre, joueur actif, restes, dernière volée par joueur, fléchettes de la volée en cours, statut bust/terminée/gagnant, suggestion de checkout, moyenne 3 fléchettes par joueur), la liste des parties de la soirée, et la moyenne de chaque joueur sur la soirée.
  - Erreurs de saisie (total impossible, checkout invalide, commande hors état) : rejet explicite par un résultat typé, sans exception non gérée et sans changer l’état.
- **Event sourcing.** La source de vérité d’une soirée est un journal ordonné d’événements : `GameStarted` (joueurs dans l’ordre + config), `VisitTotalSubmitted`, `DartThrown`, `SoireeEnded`. *Amendé le 2026-10-03* : « Rejouer » et l’ajout, le retrait ou le réordonnancement de joueurs entre deux parties sont tous un `GameStarted` avec la nouvelle liste. Rejouer calcule l’ordre tourné (`GameState.rematchOrder`), « Changer… » ouvre le setup prérempli avec cet ordre. Les joueurs de la soirée se déduisent de ses parties. L’état se calcule par un fold pur du journal. **Undo = retirer le dernier événement de saisie, puis recalculer.** Il n’y a pas de logique d’annulation propre à un écran.
- **Moteur X01.** C’est une fonction pure du fold. Une volée est soit une liste de 1 à 3 fléchettes, soit un total et un nombre de fléchettes (3 par défaut, demandé seulement au checkout). Les deux formes peuvent se mélanger dans une même partie. Moyenne 3 fléchettes = points marqués ÷ fléchettes lancées × 3. Une volée bust compte 0 point, mais ses fléchettes comptent (3 en mode total, le nombre réellement lancé en mode fléchettes).
- **Validation des totaux.** Les scores impossibles en 3 fléchettes (179, 178, 176, 175, 173, 172, 169, 166, 163) sont refusés. Les finishes Double-out impossibles (169, 168, 166, 165, 163, 162, 159, et tout reste > 170) ne peuvent pas terminer une partie. En mode total, un checkout atteignable en finissant sur un double est présumé valide.
- **Checkout.** Une suggestion de 1 à 3 fléchettes pour un reste ≤ 170 et un nombre de fléchettes restantes. En Straight-out, la suggestion est le plus court chemin quelconque. *Amendé le 2026-10-03* : les routes sont calculées (le moins de fléchettes possible, puis les fléchettes préférées) et mémorisées, plutôt que saisies à la main. La table Double-out 2–170 qui en résulte est figée dans `test/soiree/checkout_table.txt` : toute modification apparaît en diff et se relit comme du code.
- **Joueurs.** Un catalogue local d’entités (id, nom, archivé, a joué). « A joué » est posé quand une partie démarre réellement avec le joueur. Un joueur qui a joué est archivé, jamais supprimé physiquement. Noms non vides et uniques parmi les joueurs actifs, sans tenir compte de la casse (*ajouté le 2026-10-03*).
- **Persistance.** Stockage local SQLite via drift (tranche la question ouverte du one-pager : les requêtes d’historique sont naturelles en SQL et la lib est activement maintenue). Tables : joueurs, soirées, et événements de soirée (id soirée, séquence, type, payload JSON, horodatage). Chaque commande acceptée est écrite dans l’ordre, en arrière-plan : la façade reste synchrone, et l’état en mémoire fait foi pendant la partie. *Compromis assumé (2026-10-02)* : un événement pas encore écrit quand l’app est tuée est perdu. Le risque est réduit par une écriture forcée quand l’app passe en arrière-plan. Après un échec d’écriture, plus rien n’est écrit : le journal stocké reste un préfixe cohérent, jamais un journal à trous. L’undo supprime le dernier événement. L’historique se lit en rejouant les journaux, ce qui est acceptable au volume d’une soirée. La façade dépend d’un port « journal » abstrait : implémentation drift en prod, implémentation mémoire en test.
- **Démarrage offline.** L’init Supabase ne doit plus bloquer `runApp`. Elle devient non bloquante et tolérante aux erreurs, ou elle est retirée du chemin de démarrage. Aucun écran v1 ne dépend du réseau.
- **UI.**
  - Portrait seul en v1, FR seul en v1, wakelock pendant une partie.
  - Écran de jeu : en haut, la zone scoreboard (joueur actif + reste en très gros, puis les autres joueurs en liste compacte) ; en bas, le tiroir de saisie (rangée de quick-scores, pavé numérique, bouton « 0 », bascule « fléchettes », undo toujours visible).
  - Le dialog « combien de fléchettes ? » ne s’affiche qu’au checkout en mode total.
  - Haptique et bannière au changement de joueur.
- **Mode fléchette par fléchette.** Il s’active pour une seule volée, sans réglage par joueur (tranche la question ouverte du one-pager). Il revient en mode total à la volée suivante.
- **Thème.** Des tokens via une `ThemeExtension` app-specific (joueur actif, bust, checkout possible, tailles de typo du scoreboard) en plus du `ColorScheme`. Un catalogue de thèmes indexé par id string, avec un unique thème `default`. Aucune couleur ni taille de scoreboard en dur dans les widgets.
- **State management.** Un notifier fin expose le `SoiréeState` de la façade à l’UI. Les widgets n’appellent jamais le moteur ou le stockage directement.

## Testing Decisions

- **Un seul seam : la façade `Soirée`.** Les tests envoient des commandes et vérifient l’état exposé. Ils ne testent jamais les détails internes (forme des événements, fonctions du fold, tables). Un bon test se lit comme une partie : « Alice et Bob, 501 DO ; Alice 180, 180, 141 avec checkout en 3 fléchettes → Alice gagne, moyenne 167 ».
- **Couverture attendue par la façade :**
  - déroulé 501/301, Double-out et Straight-out ;
  - tous les cas de bust (sous 0, reste 1, 0 sans double) en mode total et en mode fléchettes ;
  - checkout et question du nombre de fléchettes ;
  - refus des totaux impossibles et des checkouts impossibles ;
  - mélange total/fléchettes dans une même partie ;
  - moyenne 3 fléchettes (busts inclus, partie et soirée) ;
  - undo simple, multiple, à travers les joueurs et après la fin de partie ;
  - rotation du premier joueur au rejouer ;
  - ajout ou retrait de joueur entre deux parties ;
  - suggestions de checkout sur un échantillon de restes (170, 100, 40, 3, 2, et un reste impossible → aucune suggestion).
- **Persistance par le même seam.** Dérouler une soirée avec un journal mémoire, puis reconstruire une façade sur le même journal, et vérifier que l’état est identique. Un test d’intégration fait la même chose sur le journal drift avec une base SQLite en mémoire.
- **Widgets.** Les règles métier ne se testent jamais au niveau widget, uniquement par la façade. Les widget tests couvrent : les smoke tests (l’app démarre sans réseau, l’écran de jeu affiche le joueur actif et son reste, un tap sur quick-score change le reste affiché) et le comportement purement UI que la façade ne peut pas voir (bascule total/fléchettes, dialog de checkout, bannière de tour, wakelock, reprise depuis l’accueil). *Amendé le 2026-10-02 après code review.* Le `test/widget_test.dart` du template (compteur) est remplacé.
- **Prior art.** Aucune (projet neuf, seul le test du template existe). Ces tests de façade deviennent la référence.

## Out of Scope

- Cricket Standard et Cut-Throat (v1.1, spec séparé).
- Sets/legs (First-to / Best-of), 701, Double-in.
- Stats au-delà de la moyenne 3 fléchettes (% victoires, % checkout, classements).
- Sync cloud, comptes, multi-device ; Supabase n’est pas utilisé en v1.
- Saisie vocale, cible cliquable.
- Paysage, second écran, i18n.
- Thèmes additionnels (joueurs pros, fléchettes personnalisables).
- Killer, Halve-It, Shanghai, Golf, bots, career, pubs, shop.

## Further Notes

- Hypothèse à mesurer en soirée réelle : ≤ 2 taps en moyenne par volée. Prévoir un compteur de taps activé en debug uniquement.
- Valider tôt la lisibilité du scoreboard à 2–3 m, avec un écran statique testé contre la cible avant tout polish.
- Critère de succès : 2 soirées sans MyDartTraining pour le X01.
- Pas de `CONTEXT.md` ni d’ADR : les termes Soirée, Partie, Volée, Fléchette, Reste, Bust, Checkout sont de bons candidats pour `/domain-modeling`.
