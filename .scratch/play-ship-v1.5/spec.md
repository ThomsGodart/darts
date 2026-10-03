# Spec : Ship Play Store (v1.5 → semver `1.0.0`)

Status: ready-for-agent  
Source: docs/ideas/darts-scoreboard-ui-first.md (grilling 2026-10-03)  
Depends on: v1.4 hygiène UI  
Vocabulary: **Session** — see `CONTEXT.md`.

## Tickets

| # | File | Focus |
|---|---|---|
| 01 | [issues/01-crashlytics-privacy-data-safety.md](issues/01-crashlytics-privacy-data-safety.md) | Crashes + privacy |
| 02 | [issues/02-release-android-1.0.0.md](issues/02-release-android-1.0.0.md) | Build signé 1.0.0 |
| 03 | [issues/03-listing-fr-assets.md](issues/03-listing-fr-assets.md) | Listing Play FR |
| 04 | [issues/04-closed-testing-gates.md](issues/04-closed-testing-gates.md) | Closed testing + soirées |

Order: `01` → `02` ; `03` // `01` → `04`.

## Problem Statement

Le produit est jouable et poli pour le groupe fondateur. Il faut le mettre entre les mains d’inconnus sur Google Play (Android only) sans casser l’ADN : offline, gratuit, sans pubs, sans compte.

## Solution

Release production **`1.0.0`** (les labels v1…v1.5 restent des jalons pré-ship dans `.scratch/`). Listing FR, privacy + Data safety cohérents, Crashlytics crashes-only, signing Play, closed testing ~1 semaine, gate humaine 2 soirées cercle élargi, smoke devices.

## User Stories

### Listing & store
1. As a futur utilisateur Play, I want un listing FR (titre, short/full description), so that je comprends l’app avant install.
2. As a futur utilisateur, I want 4–8 screenshots portrait et paysage, so that je vois le scoreboard partagé et le split paysage.
3. As a futur utilisateur, I want une icône et un feature graphic soignés, so that l’app paraît crédible à côté de MDT.
4. As a futur utilisateur, I want lire que l’app est gratuite et sans pubs, so that je n’ai pas peur du piège MDT.

### Privacy & data
5. As a utilisateur, I want une Privacy Policy in-app finalisée (Settings v1.3), so that le legal est accessible hors store.
6. As a utilisateur, I want un questionnaire Data safety Play cohérent avec la privacy, so that Play et l’app ne se contredisent pas.
7. As a utilisateur, I want que l’app reste 100 % locale (pas de compte / sync obligatoire), so that mes Sessions restent sur l’appareil.
8. As a utilisateur, I want que Crashlytics n’envoie que des crashes (pas d’analytics comportementaux), so that la télémétrie reste minimale.

### Release engineering
9. As a mainteneur, I want versionName/versionCode = **1.0.0** pour le premier prod, so that le semver produit est clair.
10. As a mainteneur, I want Play App Signing + keystore de release documenté hors git, so that on peut publier sans fuite de secrets.
11. As a mainteneur, I want un build release Android installable hors debug, so that le closed testing est réel.
12. As a mainteneur, I want Crashlytics (ou équivalent) branché sur le build release, so that les crashes terrain remontent.

### Gates qualité
13. As a mainteneur, I want un closed testing ~1 semaine sur une track Play, so that les inconnus cassent avant la prod ouverte.
14. As a groupe, I want 2 soirées cercle élargi (hors seulement le noyau) sans blocker, so that le produit survit hors fondateurs.
15. As a mainteneur, I want un smoke sur ≥1 device milieu de gamme + 1 petit écran, so that layout et perf de base tiennent.
16. As a joueur, I want qu’aucune pub ni IAP n’apparaisse en 1.0.0, so that l’ADN est respecté.

## Implementation Decisions

- **Seam principal** : pipeline release Android (build flavors / signing / Play Console) + SDK crash reporting. Domaine Session inchangé.
- **Semver** : jalons `.scratch/v1…v1.5` ≠ version store ; store = **`1.0.0`**.
- **Crashlytics** : crashes only ; pas d’events analytiques métier ; documenter dans privacy + Data safety.
- **Supabase** : reste off / non requis en prod (local-first).
- **Assets listing** : FR only ; screenshots incluent paysage (v1.3) et polish (v1.4).
- **Secrets** : keystore et clés Firebase/Play hors dépôt ; CI peut signer si déjà prévu, sinon process manuel documenté.
- Beaucoup de tâches restent **ready-for-human** opérationnellement (Console Play, soirées) même si la spec est agent-ready pour la partie code/checklist.

## Testing Decisions

- Smoke release APK/AAB install : Home → Setup → Game → History ; resume Session ; Settings privacy/version.
- Vérifier absence de clés debug / bannières debug en release.
- Pas de suite e2e store obligatoire ; checklist manuelle devices + closed testing.
- Prior art : `test/app_smoke_test.dart`, tests persist failure, widget smokes existants.

## Out of Scope

- iOS
- Sync / comptes / Supabase obligatoire
- Pubs, IAP, tip jar
- EN listing/app (→ post-ship `1.1.0`)
- Nouveaux jeux ou capacités
- Promotion open testing / marketing au-delà du closed testing minimal

## Further Notes

- Succès : prod (ou ready-to-promote) sans crash bloquant connu ; Data safety OK ; ADN local/gratuit/sans pubs.
- Post-ship : voir index `docs/ideas/darts-scoreboard-ui-first.md` (`1.1.0` stabilité+EN, `1.2.0` Halve-It, …).
- Tickets sous `issues/` ; 03/04 surtout `ready-for-human`.
