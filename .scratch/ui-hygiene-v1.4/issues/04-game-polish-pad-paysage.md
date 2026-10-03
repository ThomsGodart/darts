# 04: Game polish (pad, HUD, paysage)

**What to build:** Sur les écrans de jeu, quick-scores sont visuellement primaires et digits secondaires ; aucun HUD debug joueur-facing. Polish paysage des 4 kinds : hit targets ≥ 48 dp, plus d’overflow gênant. Freeze capacités.

**Blocked by:** 01 Tokens spacing/type + contrastes

**Status:** ready-for-agent

- [ ] Hiérarchie pad X01 (quick-scores > digits) ; one-tap préservé
- [ ] Pas de chrome debug visible hors kDebug intentionally gated
- [ ] Targets ≥ 48 dp + pas d’overflow paysage sur les 4 jeux
- [ ] Smoke widget / surface landscape ; pas de régression saisie
