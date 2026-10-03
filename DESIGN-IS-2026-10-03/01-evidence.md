# Evidence (consolidated)

## Structural
- Game in-play (total mode): **24** interactive controls (`visit_input.dart` segmented + 9 chips + pad + undo + miss).
- Max nesting depth GameScreen→pad: **19**.
- Repeated patterns: **6** (undo, persist banner, confirm dialogs, segmented buttons, averages, active color).
- Dead props/unused imports: **0** (analyzer clean on audited files).
- Mid-game: no in-UI leave; scoreboard rows non-interactive.

## Visual (INFERRED)
- Spacing gaps observed: `[2, 3, 4, 6, 8, 12, 16, 24, 32]` — no spacing tokens.
- Type: `DartsTokens` 120 / 40 / 32 / 20 + Material `textTheme` roles (no app textTheme override).
- Colors: 6 hex literals in `app_themes.dart` + scheme refs; seed green dark.
- Lowest computable contrast: **3.30:1** (`onCheckout` `#FFF` on `checkout` `#43A047`) — `scoreboard.dart` checkout chip.
- States: empty/loading missing home+setup; game success = game-over only; focus weak on game; disabled present setup/game.

## Copy & honesty
- French, mostly plain; jargon: `Double-out`, `DO`/`SO`, `checkout`, `BUST`, `Changer…`.
- Inflations: minimal (`pour de bon` on delete).
- Dark patterns: none hard; deferred “Terminer et commencer” vs actual `endSession` timing; `Supprimer` may archive.
- Mismatches: pad `Annuler` = undo; `Changer…` = full next-game setup; `Rejouer` rotates order (undocumented in label).

## Weight & friction (Flutter)
- 6 dependencies; `wakelock_plus` only during in-progress game (appropriate for oche use).
- Home idle animations: **0**; TurnBanner 1400ms on game only.
- Primary view network: **0** unless Supabase dart-defines set (fire-and-forget).
- Initial modals/badges: **0**.

## Accessibility
- Checkout chip contrast fails typical WCAG AA for small text (3.30:1).
- Few Semantics beyond tooltips; keyboard not primary for this product.
