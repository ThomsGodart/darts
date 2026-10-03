# Spec : Killer + Shanghai (v1.2)

Status: ready-for-agent  
Source: docs/ideas/darts-scoreboard-ui-first.md (grilling 2026-10-03)  
Depends on: v1.1 Cricket shipped (Session multi-jeux / cartes setup)  
Vocabulary: **Session** / **Game** / **Visit** / **Killer** / **Shanghai** — see `CONTEXT.md`.

## Tickets

| # | File | Focus |
|---|---|---|
| 01 | [issues/01-shanghai-jouable-e2e.md](issues/01-shanghai-jouable-e2e.md) | Shanghai E2E |
| 02 | [issues/02-killer-jouable-e2e.md](issues/02-killer-jouable-e2e.md) | Killer E2E (// 01) |
| 03 | [issues/03-cycle-session-4-jeux-historique.md](issues/03-cycle-session-4-jeux-historique.md) | Changer… + historique |

Order: `01` // `02` → `03`.

## Problem Statement

X01 + Cricket sortent le groupe de MyDartTraining pour le cœur de soirée. Il reste les jeux d’ambiance (surtout Killer) encore joués ailleurs ou à la main. On veut les compter dans la même Session, offline, avec le même rythme undo / Rejouer / Changer….

## Solution

Livrer **Killer et Shanghai ensemble** (pas de release Killer-only). Nouvelles cartes setup. Mélange avec X01/Cricket via Changer…. Rejouer = mêmes règles, rotation du premier ; en Killer, **nouvelle** attribution de chiffres. Confort tour = shell X01 (bannière + haptique + wakelock). Stats historiques minimales. Undo fléchette par fléchette. Gate release = au moins une partie Killer **et** une Shanghai complètes en soirée.

## User Stories

### Session commune
1. As a hôte, I want des cartes setup Killer et Shanghai à côté de X01/Cricket, so that j’ajoute un jeu d’ambiance sans quitter la Session.
2. As a hôte, I want enchaîner X01 ↔ Cricket ↔ Killer ↔ Shanghai via « Changer… », so that la soirée reste un seul fil.
3. As a hôte, I want que « Rejouer » garde les options du jeu et tourne le premier joueur, so that la partie suivante part vite.
4. As a hôte, I want qu’en Killer « Rejouer » tire / choisisse de **nouveaux** chiffres, so that on ne rejoue pas avec la même attribution.
5. As a hôte, I want undo fléchette par fléchette (et Fin de tour) comme en Cricket/X01, so that le modèle mental reste unique.
6. As a hôte, I want reprendre une partie Killer ou Shanghai après kill d’app, so that le journal reste fiable.
7. As a joueur, I want wakelock + bannière de tour + haptique (shell X01), so that le téléphone partagé reste confortable.
8. As a joueur, I want une ligne d’historique avec type + options courtes + gagnant, so that on relit la soirée sans nouvelles métriques complexes.
9. As a hôte, I want démarrer Killer ou Shanghai en moins de 30 s depuis le setup, so that l’ambiance ne retombe pas.

### Killer — setup & attribution
10. As a hôte, I want jouer Killer à 3–8 joueurs, so that le format party tient.
11. As a hôte, I want choisir 3 ou 5 vies au setup, so that on adapte la durée.
12. As a hôte, I want paramétrer N (défaut 1, aussi 3) doubles de son chiffre pour devenir Killer, so that on peut durcir l’entrée en Killer.
13. As a joueur, I want attribuer mon chiffre par tirage in-app (tap secteur) ou choix manuel, so that le groupe choisit son rituel.
14. As a joueur, I want que les doublons de chiffre soient refusés, so that chaque joueur a un secteur unique.
15. As a joueur, I want voir clairement la phase attribution vs phase jeu, so that je ne saisis pas un double trop tôt.

### Killer — jeu
16. As a joueur, I want devenir Killer en touchant le double de mon chiffre N fois, so that la progression est claire.
17. As a joueur Killer, I want retirer 1 vie en touchant le double d’un adversaire encore en vie, so that j’attaque.
18. As a joueur Killer, I want perdre 1 vie si je touche mon propre double, so that l’auto-hit est sanctionné.
19. As a joueur, I want être OUT à 0 vie (tours skippés, toujours visible), so that le tableau reste lisible.
20. As a joueur, I want que le dernier en vie gagne automatiquement, so that la fin de partie n’a pas besoin d’arbitre.
21. As a joueur, I want une grille de doubles (1–20 + miss) en phase jeu, so that la saisie est un tap.
22. As a hôte, I want l’écran de fin (gagnant, vies/OUT, Rejouer / Changer… / Terminer), so that la chorégraphie Session est la même.

### Shanghai — setup
23. As a hôte, I want jouer Shanghai à 1–8 joueurs, so that solo et groupe marchent.
24. As a hôte, I want choisir la longueur 1–7 (défaut) | 14–20 | 1–20, so that on choisit la durée.
25. As a hôte, I want une option « Shanghai instantané » (S+D+T) défaut on, so that on peut la couper si on préfère score seul.

### Shanghai — jeu
26. As a joueur, I want que chaque tour impose un chiffre de la séquence, so that la cible est évidente.
27. As a joueur, I want une grille S/D/T du chiffre du tour + miss, so that je saisis en un tap.
28. As a joueur, I want que hors-chiffre compte 0 et consomme une fléchette, so that les ratés sont rapides.
29. As a joueur, I want fin de visite auto à la 3ᵉ fléchette et « Fin de tour » pour couper, so that le rythme suit Cricket.
30. As a joueur, I want gagner instantanément sur S+D+T du chiffre dans la même visite quand l’option est on, so that le Shanghai mythique est reconnu.
31. As a joueur, I want que le plus haut score cumulé gagne en fin de séquence sinon, so that la partie a toujours un vainqueur.
32. As a hôte, I want l’écran de fin avec score / Shanghai win + Rejouer / Changer… / Terminer, so that on enchaîne.

## Implementation Decisions

- **Seam principal** : mêmes seams v1.1 — `GameConfig` discriminé + fold par kind + cartes setup. Killer et Shanghai sont deux nouveaux kinds, pas des apps séparées.
- **Ship atomique** : une seule livraison contenant les deux ; pas de flag Killer-only en prod.
- **Événements** : réutiliser `DartThrown` + `VisitEnded`. Killer ajoute un événement d’**attribution de chiffre** (joueur → secteur) pendant la phase `assigning`.
- **Killer state machine** : `assigning | playing | finished`. En `assigning`, seuls les events d’attribution (et undo) s’appliquent. En `playing`, grille doubles ; joueurs OUT skippés dans la rotation.
- **Killer config** : vies (3|5), doubles-to-killer N (défaut 1). Attribution mode : tirage (saisie secteur comme dart picker X01) ou manuel avec refus doublon.
- **Shanghai config** : longueur de séquence + flag shanghai-instant. Score cumulatif par joueur ; détection S+D+T dans la visite courante.
- **Rematch Killer** : même config vies/N, **nouvelle** phase attribution (chiffres non repris).
- **UI tour** : réutiliser le shell confort X01 (TurnBanner + haptique + wakelock) — pas le mode « colonne ▶ seule » du Cricket.
- **Historique** : ligne minimale (type + options courtes + gagnant ; score Shanghai ou résumé vies Killer). Pas de MPR / % doubles en v1.2.
- **Persistance** : étendre discriminant `kind` (`killer` | `shanghai`) + payloads ; migration/codec tests comme v1.1.

## Testing Decisions

- Comportement externe façade d’abord : vies, self-hit, last standing, skip OUT, attribution doublon refusée, Shanghai instant on/off, longueurs, undo, rematch ré-attribue.
- Widget smoke : cartes setup, grille doubles, grille S/D/T, fin de partie, Changer… vers/depuis X01/Cricket.
- Prior art : tests façade Session v1/v1.1, `game_screen_test`, `setup_screen_test`, migration codec.
- Gate humaine (hors CI) : 1 partie Killer + 1 Shanghai complètes en soirée réelle.

## Out of Scope

- Halve-It, Golf, Baseball, 170, Super Bull, Around the Clock.
- Voix, cible cliquable, paysage (v1.3), 2e écran, thèmes pro, sync.
- Glyphes Cricket / whiteboard / no-slop.
- Nouvelles métriques avancées (MPR Killer, % doubles, etc.).
- Release Killer sans Shanghai.

## Further Notes

- Succès : setup &lt; 30 s ; plus de papier / MDT pour Killer & Shanghai en soirée.
- Tickets sous `issues/` ; frontier = 01 et 02 en parallèle après v1.1.
