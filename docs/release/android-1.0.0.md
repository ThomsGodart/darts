# Android release `1.0.0`

Semver store = **1.0.0** (`pubspec.yaml` `version: 1.0.0+1`, `lib/app_version.dart`).

## Signing (secrets hors git)

1. Create an upload keystore (once):

```bash
keytool -genkey -v -keystore ~/keys/darts-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. Copy `android/key.properties.example` → `android/key.properties` and fill paths/passwords.
3. Never commit `*.jks`, `*.keystore`, or `key.properties` (already gitignored under `android/`).
4. Enable **Play App Signing** in Play Console; upload the AAB signed with the upload key.

Release Gradle uses the release signingConfig when `key.properties` exists; otherwise it falls back to debug signing so local `flutter run --release` still works.

## Crashlytics (crashes only)

1. Create a Firebase Android app whose package name matches `applicationId` in `android/app/build.gradle.kts`.
2. Place `android/app/google-services.json` (gitignored).
3. Run `flutterfire configure` and replace `lib/firebase_options.dart`, then set `DefaultFirebaseOptions.isConfigured = true`.
4. Rebuild release. `initCrashReporting()` runs only in release and never blocks offline startup.
5. Do **not** log custom analytics / business events — crashes only (see privacy + Data safety).

Without steps 2–3, release still starts; Crashlytics is a quiet no-op.

## Build

```bash
flutter build appbundle --release
# or
flutter build apk --release
```

## Smoke (manual)

Home → Nouvelle session → Game → Partie suivante / History → Settings (version `1.0.0` + privacy) → resume Session after kill.

## Application id

Change `com.example.darts_points_counter` to a stable reverse-DNS id **before** the first Play upload; it cannot be changed later.
