# Play Console — Data safety (aligné privacy in-app)

Answer the questionnaire to match `assets/privacy_fr.txt`, Crashlytics crashes-only, and session sharing.

## Data collected

| Type | Collected? | Notes |
|---|---|---|
| App activity / gameplay | No (not collected) | Sessions stay on device. A session the user chooses to share is relayed live to the devices that typed its code (Supabase Realtime broadcast): in transit only, never stored — Play's "ephemeral processing", which is not collection |
| Player names | No (not collected) | Free-text names, relayed with a shared session as above; no accounts |
| Personal info (name, email) | No | No accounts |
| Financial info | No | No IAP / ads |
| Location | No | |
| Crash logs | **Yes** (when Crashlytics configured) | Technical crash reports only |
| Diagnostics / performance | No beyond crash reports | No Analytics SDK events |
| Device ids | Possibly via Crashlytics | As required by Firebase Crashlytics |

## Purposes

- **Crashlytics**: App functionality / stability (find and fix crashes).
- **Not used for**: advertising, personalization marketing, fraud advertising, account management.

## Sharing

- Crash data processed by Google Firebase when Crashlytics is enabled.
- No sale of data.
- No ads SDK.

## Security practices

- Data encrypted in transit (Firebase; shared sessions over TLS).
- Users can request deletion of local data by uninstalling the app.
- Optional: document contact email on the Play listing.

## Declarations to tick carefully

- App does **not** require a Google Account.
- Data is **not** required for the app to work (local-first without Crashlytics still works; sharing a session is opt-in, per session).
- Collect crash logs: yes (production with Firebase wired).
