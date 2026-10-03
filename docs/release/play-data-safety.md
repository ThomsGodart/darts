# Play Console — Data safety (aligné privacy in-app)

Answer the questionnaire to match `assets/privacy_fr.txt` and Crashlytics crashes-only.

## Data collected

| Type | Collected? | Notes |
|---|---|---|
| App activity / gameplay | No (not off-device) | Sessions stay on device |
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

- Data encrypted in transit (Firebase).
- Users can request deletion of local data by uninstalling the app.
- Optional: document contact email on the Play listing.

## Declarations to tick carefully

- App does **not** require a Google Account.
- Data is **not** required for the app to work (local-first without Crashlytics still works).
- Collect crash logs: yes (production with Firebase wired).
