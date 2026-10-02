# 01: App shell offline-first + thème `default`

**What to build:** L’app s’ouvre sur un écran d’accueil propre (plus de template compteur), y compris en mode avion. L’init Supabase ne bloque plus le démarrage : elle est non bloquante et tolère les erreurs, ou elle est retirée du chemin de démarrage. Tout le style passe par des tokens de thème : une `ThemeExtension` app-specific (joueur actif, bust, checkout possible, tailles de typo du scoreboard) s’ajoute au `ColorScheme`, et un catalogue de thèmes indexé par id string contient un seul thème, `default`. Prefactoring qui prépare les slices suivantes. Voir spec : Implementation Decisions (Démarrage offline, Thème), user stories 49, 52.

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [ ] Cold start en mode avion OK, sans erreur ni écran bloqué
- [x] Le test widget du template (compteur) est remplacé par un smoke test : l’app démarre sans réseau
- [x] Catalogue de thèmes avec un thème `default`, sélectionné par son id
- [x] `ThemeExtension` exposant au minimum : couleur joueur actif, couleur bust, couleur checkout possible, tailles de typo du scoreboard
- [x] Aucune couleur hardcodée dans les écrans

## Comments

- 2026-10-02 — Implémenté : `DartsTokens` (ThemeExtension), catalogue `appThemes` avec `default`, `initBackend` non bloquant et tolérant (lancé sans `await` avant `runApp`), écran d’accueil minimal. `flutter analyze` propre, 6 tests verts. Non vérifié sur appareil réel en mode avion.
