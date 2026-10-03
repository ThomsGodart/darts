# Spec : Paysage / responsive + stub Settings (v1.3)

Status: ready-for-agent  
Source: docs/ideas/darts-scoreboard-ui-first.md (grilling 2026-10-03)  
Depends on: v1.2 Killer + Shanghai (les 4 types de jeu existent)  
Vocabulary: **Session** / **Game** — see `CONTEXT.md`.

## Tickets

| # | File | Focus |
|---|---|---|
| 01 | [issues/01-gameshell-paysage-x01.md](issues/01-gameshell-paysage-x01.md) | Shell + X01 |
| 02 | [issues/02-adapters-cricket-killer-shanghai.md](issues/02-adapters-cricket-killer-shanghai.md) | 3 adapters |
| 03 | [issues/03-settings-stub-privacy-version.md](issues/03-settings-stub-privacy-version.md) | Settings stub (// 01) |

Order: `01` → `02` ; `03` // `01`.

## Problem Statement

Après X01, Cricket, Killer et Shanghai, le téléphone reste souvent posé près de la cible. Le portrait seul gaspille la largeur et force des layouts qu’il faudra casser au polish. Avant la passe UI/UX (v1.4) et le ship Play (v1.5), il faut une fondation d’orientation + un stub Settings legal minimal — sans nouvelle capacité produit.

## Solution

Aucun nouveau jeu, voix, cible, sync, ni 2e écran. Pattern unique en paysage pour les **4** types : **état à gauche | saisie à droite** (proportions ~50/50 ou 40/60, UI correcte / tokens, pas belle). Accueil, setup, historique : usage portrait naturel ; écrans de jeu : orientation libre (système). Tablette / wide : même split (pas de layout tablette dédié). Settings depuis l’accueil : Privacy Policy in-app + version. Le beau est **v1.4**.

## User Stories

### Orientation & layout jeu
1. As a joueur, I want tourner le téléphone en paysage pendant une partie X01, so that scoreboard et keypad utilisent la largeur.
2. As a joueur, I want le même split état|saisie en Cricket, Killer et Shanghai, so that je n’apprends pas 4 layouts.
3. As a joueur, I want en X01 paysage le reste/scoreboard à gauche et keypad + quick-scores à droite, so that l’état reste lisible à distance.
4. As a joueur, I want en Cricket paysage la matrice marks à gauche et la grille D/S/T à droite, so that saisie et standing coexistent.
5. As a joueur, I want en Killer paysage vies/OUT/statut à gauche et grille doubles (ou attribution) à droite, so that la phase reste claire.
6. As a joueur, I want en Shanghai paysage scores + chiffre du tour à gauche et grille S/D/T à droite, so that la cible imposée reste visible.
7. As a joueur, I want que le portrait conserve les comportements actuels (pas de régression), so that les soirées « téléphone en main » ne cassent pas.
8. As a joueur, I want pouvoir tourner librement pendant le jeu (orientation système), so that poser le téléphone en paysage marche sans menu.
9. As a joueur, I want que Home / Setup / History restent confortables en portrait, so that le setup n’oblige pas le paysage.
10. As a joueur, I want le même split sur une tablette large, so that on n’attend pas un layout tablette dédié.
11. As a joueur, I want que wakelock reste actif en jeu paysage comme en portrait, so that l’écran ne s’éteint pas près de la cible.
12. As a joueur, I want qu’une rotation mid-visite ne perde pas la saisie en cours, so that tourner le téléphone n’est pas destructif.

### Settings stub
13. As a hôte, I want ouvrir Settings depuis l’accueil (engrenage / bouton), so that privacy et version sont trouvables.
14. As a hôte, I want lire la Privacy Policy in-app (texte scrollable), so that le legal minimal est là avant le store.
15. As a hôte, I want voir le numéro de version de l’app, so that je peux rapporter un bug précisément.
16. As a hôte, I want que Settings n’exige ni compte ni feature toggles nouveaux, so that le stub reste minimal.

### Qualité « correcte »
17. As a joueur, I want aucun overflow/clip bloquant sur les 4 jeux en paysage sur un téléphone courant, so that la soirée n’est pas cassée.
18. As a joueur, I want des hit targets utilisables (pas forcément polish 48 dp partout — ça c’est v1.4), so that je peux saisir en paysage sans rage-quit.

## Implementation Decisions

- **Seam principal (unique)** : un shell de layout de jeu (`GameShell` ou équivalent) qui compose **état** + **saisie**. Portrait = stack actuel ; paysage / wide = `Row` split. Les 4 écrans de jeu fournissent seulement les deux slots — pas 4 layouts paysage distincts.
- **Breakpoint** : largeur (OrientationBuilder / MediaQuery) ; tablette = même split.
- **Orientation policy** : écrans de jeu = libre ; Home/Setup/History = portrait préféré / naturel (pas de lock agressif qui casse le partage d’appareil si coûteux — viser « ne force pas le paysage » hors jeu).
- **Settings** : nouvelle route depuis Home ; contenu Privacy = asset texte / markdown scrollable ; version via `package_info_plus` (ou équivalent déjà acceptable dans l’écosystème Flutter du projet).
- **Pas de polish** : tokens existants, pas de refonte spacing/contrast (v1.4). Pas de nouvelle capacité domaine.
- **État Session** : aucun changement de règles / events ; UI-only + navigation Settings.

## Testing Decisions

- Widget tests avec **surface size** portrait et paysage (prior art `test/game/game_screen_test.dart`) — au minimum X01 + Cricket ; smoke Killer/Shanghai si leurs screens existent.
- Vérifier qu’une rebuild orientation ne reset pas le controller / la visite en cours.
- Smoke Settings : ouverture depuis Home, présence version, scroll Privacy.
- Pas de golden obligatoire en v1.3 ; pas de tests domaine nouveaux.

## Out of Scope

- Polish typo/motion/hit-targets store-ready → **v1.4**
- Listing Play, Crashlytics, closed testing → **v1.5**
- i18n EN, iOS, sync, voix, cible, Halve-It, thèmes pro
- Layout tablette dédié, 2e écran

## Further Notes

- Succès : une soirée avec ≥1 partie de chaque type en paysage sans bug bloquant de rotation/layout ; Privacy + version accessibles.
- Tickets sous `issues/` ; frontier = 01 et 03.
- Roadmap : v1.4 polish ; v1.5 ship `1.0.0`.
