````
/make-plan Redesign the shared-phone X01 game UI shell (Home, Setup, Game scoreboard+input, History). Current design failed a Dieter Rams audit at 19/30 with critical gaps in principles #3 aesthetic and #8 thorough (also #4 labels).

Verdict paragraph:
> REDESIGN — Total 19/30; the product bones fit a dart player (huge remaining, one-tap visits, offline, session loop), but the UI shell (spacing, contrast, missing states, dishonest chrome labels) must be redesigned from purpose rather than lightly restyled.

Why redesign and not refine: Total below 20; aesthetic system and state thoroughness are not salvageable by isolated tweaks without a coherent shell pass (aligns with roadmap jalon v1.4 hygiene, but start from purpose not Material defaults).

Preserve from current design (MUST keep):
- Scoreboard-first hierarchy: active remaining ~120px, active player name ~40px (`lib/theme/app_themes.dart` DartsTokens; `lib/game/scoreboard.dart`).
- One-tap quick-scores + total pad + dart-by-dart mode (`lib/game/visit_input.dart`).
- Theme id `default` + `DartsTokens` roles: activePlayer, bust, checkout (`lib/theme/darts_tokens.dart`, `app_themes.dart`).
- Session loop: Rejouer / next setup / history; offline-first (no ads).
- Domain event model and French UI language intent (`CONTEXT.md`).

Discard:
- Ad-hoc spacing litter `[2,3,4,6,8,12,16,24,32]` without tokens — caused failure on #3.
- Checkout chip colors at ~3.30:1 contrast (`checkout`/`onCheckout`) — #3 / a11y.
- Label `Annuler` for undo (`visit_input.dart:92`) and `Changer…` for next-game setup (`game_screen.dart:318`) — #4/#6.
- Missing empty/loading treatments on home resume + setup catalog — #8.
- Raw `$error` SnackBars — #6/#8.

Top moves:
1. #3 aesthetic: Single spacing + type scale in tokens; fix all text/icon contrasts on semantic colors to ≥4.5:1 (checkout first).
2. #8 thorough: Empty/loading/error/success/focus/disabled checklist on Home, Setup, Game, History.
3. #4 understandable: Plain French chrome — « Annuler la saisie », « Partie suivante », history without opaque DO/SO.
4. #10 little design: Visual hierarchy on the pad (quick-scores primary, digits secondary); no player-facing debug chrome.
5. #5 unobtrusive: Remaining + active name stay figure; turn change haptic OK; banner must not compete with scoreboard.

Redesign principles in priority order:
1. #2 Useful — still fewest taps per visit; never add confirm steps.
2. #4 Understandable — every chrome label matches behavior; dart jargon OK, app jargon not.
3. #10 As little design as possible — distance-readable scoreboard beats decoration.
4. #3 Aesthetic — one system, store-ready calm (feeds jalon v1.4).
5. #8 Thorough — no blank loading holes at the oche.

Deliverables for the plan:
- New information architecture (not derived from old Material scaffolding)
- New primary flow (low-fi, labeled, compared side-by-side to current GameScreen)
- States checklist (empty, loading, error, success, focus, disabled)
- Migration path: keep domain/session APIs; swap UI shell incrementally if needed
- Cutover criteria: contrast audit pass; label audit pass; empty/loading on home+setup; quick-score still ≤1 tap

Anti-patterns:
- Porting old structure under new colors
- Keeping both shells behind a flag indefinitely
- Redesigning to a purple/cream AI aesthetic trend
- Touching domain fold/rules in this UI redesign pass
- Adding onboarding that blocks “Nouvelle session” < 30s
````
