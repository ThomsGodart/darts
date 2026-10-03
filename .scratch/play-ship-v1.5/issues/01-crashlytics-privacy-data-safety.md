# 01: Crashlytics + privacy / Data safety

**What to build:** Le build release remonte les **crashes uniquement** (pas d’analytics comportementaux). Privacy in-app et questionnaire Data safety Play décrivent la même chose ; l’app reste local-first sans compte obligatoire.

**Blocked by:** None (can start immediately) — requires v1.4 shipped.

**Status:** ready-for-agent

- [ ] SDK crash reporting branché sur release uniquement (ou équivalent documenté)
- [ ] Aucun event analytique métier
- [ ] Privacy in-app alignée avec Data safety (texte finalisé)
- [ ] Checklist / test smoke : app démarre release avec reporting initialisé sans casser l’offline
