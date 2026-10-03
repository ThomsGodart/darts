# Scorecard — dart player / shared-phone X01 UI

1. Good design is innovative — Score: **2**/3  
   Evidence: Scoreboard-first + no-confirm + quick-scores vs MDT ads/density (`scoreboard.dart`, `visit_input.dart`).  
   Justification: Clear improvement on peer apps, not a new interaction paradigm.

2. Good design is useful — Score: **3**/3  
   Evidence: One-tap quick-score path; remaining 120px for distance reading (`app_themes.dart:29`, `visit_input.dart:118–122`).  
   Justification: Primary oche task is directly supported with minimal steps.

3. Good design is aesthetic — Score: **1**/3  
   Evidence: No spacing token system `[2…32]`; checkout contrast 3.30:1; Material defaults + ad-hoc sizes.  
   Justification: One jarring contrast violation plus inconsistent spacing — not a single visible system.

4. Good design is understandable — Score: **2**/3  
   Evidence: Dart jargon OK for players (`BUST`, `Bull`); app labels mismatch — `Annuler`=undo (`visit_input.dart:92`), `Changer…` (`game_screen.dart:318`).  
   Justification: Domain language clear; 1–2 chrome labels need decoding.

5. Good design is unobtrusive — Score: **2**/3  
   Evidence: Content = remaining/name; chrome = bottom pad; TurnBanner overlays briefly (`turn_banner.dart`).  
   Justification: Chrome visible but mostly ground; banner competes briefly.

6. Good design is honest — Score: **2**/3  
   Evidence: Persist banner truthful (`persist_failure_banner.dart:7–8`); soft mismatch Terminer-et-commencer deferred end (`home_screen.dart:100` vs `session_launcher.dart:36`).  
   Justification: ≤1 minor honesty soft spot; no dark patterns.

7. Good design is long-lasting — Score: **2**/3  
   Evidence: Dark sports green/amber scoreboard language; single theme `default` (`app_themes.dart`).  
   Justification: Not trend-chasing; still reads as generic Material sports, not timeless craft.

8. Good design is thorough down to the last detail — Score: **1**/3  
   Evidence: Missing empty/loading on home & setup; weak focus on game (01-evidence states table).  
   Justification: 2–3 states missing or rough.

9. Good design is environmentally friendly — Score: **2**/3  
   Evidence: Offline-first; 0 home animations; wakelock only in-game (`screen_awake.dart`); optional backend.  
   Justification: Good attention/energy hygiene; wakelock is justified for the task.

10. Good design is as little design as possible — Score: **2**/3  
    Evidence: Home ~3 actions; game pad 24 controls largely task-required; debug HUD extra (`game_screen.dart:363`).  
    Justification: ≤2 removable elements (debug, some label duplication); density is mostly earned.

## Total: **19**/30
