# Android release `1.0.0`

Semver store = **1.0.0** (`pubspec.yaml` `version: 1.0.0+1`, `lib/app_version.dart`).

**Application id:** `com.godart.darts` (stable — do not change after first Play upload).

## Signing (secrets hors git)

Upload keystore lives **outside** the repo (e.g. `~/keys/darts-upload.jks`). Local wiring:

1. `android/key.properties` (gitignored) — copy from `android/key.properties.example`.
2. Password backup: keep a copy of the store password in a password manager (also optional local file next to the keystore, never commit).
3. Enable **Play App Signing** in Play Console; upload an AAB signed with the upload key.

```bash
flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab
```

Without `key.properties`, Gradle falls back to debug signing so `flutter run --release` still works.

## Crashlytics (crashes only)

1. Create a Firebase Android app with package name **`com.godart.darts`**.
2. Place `android/app/google-services.json` (gitignored).
3. Run `flutterfire configure` and replace `lib/firebase_options.dart`, then set `DefaultFirebaseOptions.isConfigured = true`.
4. Rebuild release. `initCrashReporting()` runs only in release and never blocks offline startup.
5. Do **not** log custom analytics / business events — crashes only (see privacy + Data safety).

Without steps 2–3, release still starts; Crashlytics is a quiet no-op.

## Smoke (manual)

Home → Nouvelle session → Game → Partie suivante / History → Settings (version `1.0.0` + privacy) → resume Session after kill.
