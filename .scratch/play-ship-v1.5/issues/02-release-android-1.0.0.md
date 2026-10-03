# 02: Release Android `1.0.0`

**What to build:** Un AAB/APK release signé avec versionName/versionCode **1.0.0**, installable hors debug, prêt pour upload Play (App Signing). Secrets hors git. Smoke : Home → Setup → Game → History → Settings.

**Blocked by:** 01 Crashlytics + privacy / Data safety

**Status:** ready-for-human

- [x] versionName / versionCode = 1.0.0 (`pubspec` + `appVersionName`)
- [x] Signing Gradle + `key.properties.example` ; secrets gitignored ; docs
- [x] `flutter build apk --release` OK (fallback debug signing sans keystore)
- [x] Smoke widget parcours Session (suite existante)
- [x] `applicationId` = `com.godart.darts`
- [x] Keystore upload local + `key.properties` (hors git) ; AAB `app-release.aab` signé
- [ ] Smoke manuel install release sur device
- [ ] Upload Play Console + App Signing

## Comments

- 2026-10-03: agent — version 1.0.0, id `com.godart.darts`, keystore `~/keys/darts-upload.jks`, AAB signé. Reste : install device + Console.
