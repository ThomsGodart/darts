# Verdict

**REDESIGN** — Total **19**/30 (below 20); no principle scored 0, but aesthetic (#3) and thoroughness (#8) are weak enough that iterating chrome on the current Material sprawl will not get a dart player a calm, distance-readable tool.

The **product bones fit a dart player** (huge remaining, one-tap visits, offline, session loop). What fails the audit is the **UI shell**: inconsistent spacing, failing checkout contrast, missing empty/loading states, and chrome labels that lie about behavior (`Annuler`, `Changer…`).

## Highest-leverage moves
1. **#3 aesthetic** — One spacing scale + fix checkout (and any) contrast to ≥4.5:1. Evidence: `app_themes.dart` tokens; scoreboard checkout chip ~3.30:1.
2. **#8 thorough** — Empty/loading for home resume + setup catalog; structured error (no raw `$error`). Evidence: `home_screen.dart` FutureBuilder; `setup_screen.dart` load.
3. **#4 understandable** — Rename `Annuler`→`Undo`/« Annuler la saisie »; `Changer…`→« Partie suivante »; spell out DO/SO in history. Evidence: `visit_input.dart:92`, `game_screen.dart:318`, `formatting.dart:18–19`.
4. **#10 little design** — Cull debug HUD from player-facing debug noise; tighten pad hierarchy (quick-scores vs digits). Evidence: `game_screen.dart:363`, 24 controls in `visit_input.dart`.
5. **#5 unobtrusive** — Keep scoreboard as figure; ensure TurnBanner never steals hit targets (already `IgnorePointer` — keep, shorten, or move to edge). Evidence: `turn_banner.dart`.
