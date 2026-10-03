# Spec : Hygiène UI/UX (v1.4)

Status: ready-for-agent  
Source: docs/ideas/darts-scoreboard-ui-first.md (grilling 2026-10-03) + `DESIGN-IS-2026-10-03/`  
Depends on: v1.3 paysage (shells portrait/paysage en place)  
Vocabulary: **Session** / **Game** — see `CONTEXT.md`.

## Tickets

| # | File | Focus |
|---|---|---|
| 01 | [issues/01-tokens-spacing-contrastes.md](issues/01-tokens-spacing-contrastes.md) | Tokens + contrastes |
| 02 | [issues/02-etats-home-setup.md](issues/02-etats-home-setup.md) | Empty/loading/error |
| 03 | [issues/03-copy-chrome-history.md](issues/03-copy-chrome-history.md) | Labels FR |
| 04 | [issues/04-game-polish-pad-paysage.md](issues/04-game-polish-pad-paysage.md) | Pad + paysage |
| 05 | [issues/05-glyphes-cricket-optionnel.md](issues/05-glyphes-cricket-optionnel.md) | Opt. `/XO` |

Order: `01` → (`02` // `03` // `04`) ; `05` gate humain.

## Problem Statement

Les capacités (X01 → Cricket → Killer/Shanghai) et la fondation paysage existent, mais le chrome UI échoue un audit Rams (**19/30**, verdict REDESIGN du shell) : contrastes faibles, spacing ad hoc, états empty/loading absents, labels trompeurs (`Annuler` = undo, `Changer…`). Avant le ship Play, il faut une passe hygiène — pas de nouvelle capacité.

## Solution

Redesign / refine du **shell UI** (Home, Setup, Game × 4 types, History, Settings) autour des tokens `default` : spacing + type scale uniques, contrastes ≥ 4.5:1, états empty/loading/error/success/focus/disabled, labels FR honnêtes, polish paysage (targets ≥ 48 dp, overflows), hiérarchie pad. Freeze capacités. Réf. `DESIGN-IS-2026-10-03/03-verdict.md` et `04-handoff-prompt.md`.

## User Stories

### Design system & lisibilité
1. As a joueur, I want un seul système d’espacement et de typo sur toute l’app, so that l’UI ne paraît pas bricolée.
2. As a joueur, I want que le chip checkout (et tout texte sur couleur sémantique) ait un contraste ≥ 4.5:1, so that je le lis à distance et en accessibilité.
3. As a joueur, I want que le reste actif et le nom du joueur actif restent la figure dominante, so that le scoreboard-first n’est pas dilué.
4. As a joueur, I want des hit targets ≥ 48 dp en jeu (surtout paysage), so that je tape sans rater près de la cible.
5. As a joueur, I want aucun overflow/clip gênant en paysage sur les 4 jeux, so that la fondation v1.3 devient jouable confortablement.

### États & erreurs
6. As a hôte, I want un état empty clair sur Home s’il n’y a pas de Session à reprendre, so that je ne vois pas un trou de chargement.
7. As a hôte, I want un état loading sur Home (resume) et Setup (catalogue), so that j’attends sans UI cassée.
8. As a hôte, I want des erreurs structurées (pas de `$error` brut), so that un échec de persistance reste compréhensible.
9. As a joueur, I want des états disabled/focus cohérents sur le pad et les cartes, so that les actions impossibles sont évidentes.

### Labels & chrome (FR)
10. As a joueur, I want que le bouton d’undo de saisie dise la vérité (ex. « Annuler la saisie » / Undo), so that je ne crois pas annuler la partie.
11. As a hôte, I want « Partie suivante » (ou équivalent honnête) à la place de « Changer… », so that l’action setup entre parties est claire.
12. As a joueur, I want l’historique sans sigles opaques DO/SO, so that Double-out / Straight-out se lisent en français.
13. As a joueur, I want que la bannière de tour (X01/Killer/Shanghai) ne vole pas les targets du scoreboard, so that elle reste unobtrusive.

### Pad & hiérarchie
14. As a joueur, I want les quick-scores visuellement primaires et les digits secondaires, so that le chemin ≤1 tap reste évident.
15. As a joueur, I want aucun HUD debug joueur-facing, so that l’écran de jeu reste calme.

### Cricket conditionnel
16. As a joueur Cricket, I want des glyphes `/ X O` **seulement si** les soirées v1.1 ont dit « pastilles illisibles », so that on ne change pas un système qui marche.

### Freeze & succès
17. As a hôte, I want qu’aucune nouvelle capacité (voix, cible, jeu, sync, iOS) n’arrive dans cette passe, so that le polish ne dérive pas.
18. As a groupe fondateur, I want pouvoir voter « plus store-ready que MDT », so that v1.5 a un gate humain clair.

## Implementation Decisions

- **Seam principal** : thème / `DartsTokens` + shells UI existants (Home, Setup, GameShell v1.3, History, Settings). **Aucun** changement de fold / events / règles.
- **Preserve** : scoreboard-first (reste ~120, nom ~40), one-tap visits, thème id `default`, Session loop, offline, UI française.
- **Spacing** : une scale tokenisée ; supprimer les littéraux ad hoc pour les gaps courants.
- **Contraste** : corriger `checkout` / `onCheckout` (et autres sémantiques) ≥ 4.5:1.
- **Copy pass** : inventaire des labels chrome trompeurs (undo, partie suivante, out rules en history).
- **États** : checklist empty/loading/error/success/focus/disabled sur Home, Setup, Game, History.
- **Paysage polish** : mêmes slots v1.3, qualité visuelle + targets.
- **Glyphes Cricket** : feature flag / ticket séparé **bloqué** jusqu’à feedback soirée v1.1 explicite.
- **Anti-patterns** : pas de thème purple/cream AI ; pas de double shell derrière flag indéfini ; pas d’onboarding qui bloque « Nouvelle session » &lt; 30 s.

## Testing Decisions

- Tests thème / contraste (prior art `test/theme/app_themes_test.dart`) pour les paires sémantiques critiques.
- Widget tests : empty/loading Home + Setup ; labels clés présents ; pas de régression saisie one-tap (game/setup smoke).
- Smoke paysage : pas d’overflow sur surfaces landscape (suite v1.3).
- Ne pas tester les détails de paint Material ; tester le comportement visible (texte, présence d’états, actions).

## Out of Scope

- Nouvelles capacités produit
- Listing Play / Crashlytics / closed testing → **v1.5**
- i18n EN → post-ship `1.1.0`
- Refonte domaine / règles
- Glyphes Cricket sans douleur v1.1 confirmée

## Further Notes

- Verdict Rams : REDESIGN shell, pas les bones produit.
- Succès : vote groupe + checklist design (contrastes, targets, overflows, états).
- Tickets sous `issues/` ; frontier = 01.
