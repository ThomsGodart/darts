# 01: Crashlytics + privacy / Data safety

**What to build:** Le build release remonte les **crashes uniquement** (pas d’analytics comportementaux). Privacy in-app et questionnaire Data safety Play décrivent la même chose ; l’app reste local-first sans compte obligatoire.

**Blocked by:** None (can start immediately) — requires v1.4 shipped.

**Status:** ready-for-human

- [x] Seam crash reporting release-only + deps Firebase (no-op sans config)
- [x] Aucun event analytique métier
- [x] Privacy in-app + checklist Data safety alignées
- [x] Tests : init ne casse pas l’offline
- [ ] `flutterfire configure` + `google-services.json` + `isConfigured = true` (humain)
- [ ] Vérifier un crash release remonte bien dans la console Firebase

## Comments

- 2026-10-03: agent — `initCrashReporting`, privacy, `docs/release/play-data-safety.md` / `android-1.0.0.md`. Crashlytics live = étape humaine (projet Firebase).
