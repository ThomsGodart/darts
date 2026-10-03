# Darts Points Counter — Roadmap soirée → Play

## Problem Statement
How might we faire tourner une soirée fléchettes entre potes sur **un seul téléphone partagé**, plus vite et plus lisiblement que MyDartTraining, offline — puis publier sur **Play** sans pubs ni compte ?

## Recommended Direction
Scorer **Session** local-first : v1 X01 → v1.1 Cricket → v1.2 Killer+Shanghai → v1.3 fondation paysage → v1.4 hygiène UI → v1.5 ship Play (Android).

Succès intermédiaire : plus de MDT. Succès ship : closed testing + soirées cercle élargi, listing FR, crash reporting, 100% local, gratuit sans pubs.

## Key Assumptions to Validate
- [ ] **La saisie bat MDT** (X01) — ≤ 2 taps/volée en moyenne ; 2 soirées « on garde ça ».
- [ ] **Cricket pastilles** lisibles à 2–3 m.
- [ ] **Killer + Shanghai** joués à la place de MDT / papier.
- [ ] **Paysage** : 4 types jouables une soirée sans casse.
- [ ] **Polish 1.4** : vote « plus store-ready que MDT » + checklist design.
- [ ] **1.5** : closed testing 1 semaine + 2 soirées hors noyau dur sans blocker.

## MVP Scope

**In (v1)** — X01 Session, offline-first, thème `default`, moyenne 3D.  
**In (v1.1)** — [`.scratch/cricket-v1.1/spec.md`](../../.scratch/cricket-v1.1/spec.md)  
**In (v1.2)** — [`.scratch/killer-shanghai-v1.2/spec.md`](../../.scratch/killer-shanghai-v1.2/spec.md)

**In (v1.3)** — [`.scratch/landscape-v1.3/spec.md`](../../.scratch/landscape-v1.3/spec.md)
- Fondation **paysage / responsive** uniquement (pas de nouvelle capacité)
- Pattern **état | saisie** pour X01, Cricket, Killer, Shanghai
- Jeu = orientation libre ; accueil/setup/historique = portrait naturel
- Même split sur tablette (pas de layout dédié)
- Settings stub : **privacy in-app** + **version**
- UI correcte/tokens — le beau est 1.4

**In (v1.4) — hygiène UI/UX** (stub)
- Design system : typo, spacing, motion, états, empty/error, contrastes
- Polish **paysage** (hit targets, overflows, proportions)
- **Freeze** capacités (pas de voix/cible/jeux/sync)
- Glyphes Cricket `/XO` : **seulement si** douleur après soirées 1.1
- Succès : vote groupe « store-ready vs MDT » + checklist design

**In (v1.5) — ship Play** (stub) → **semver `1.0.0`**
- Listing **FR** (titre, descriptions, screenshots portrait+paysage, icône, feature graphic)
- **Crashlytics** (pas d’analytics comportementaux)
- **100% local** — pas de comptes / sync ; Supabase reste off
- **Gratuit, sans pubs**
- Gate : checklist store + closed testing ~**1 semaine** + **2 soirées** cercle élargi
- Android only (pas iOS)

## Versioning
- Les labels **v1 … v1.5** dans `.scratch/` / cette idea sont des **jalons pré-ship** (historique des tickets).
- Le premier build **Play production** = **`1.0.0`**.
- Ensuite : minors **`1.1.0`**, **`1.2.0`**, … Un **`2.0.0`** seulement pour un changement de promesse (ex. sync cloud).

## Post-shipping (après `1.0.0`)

Priorisation : **Crashlytics + reviews Play** d’abord ; les jeux additionnels restent dans la file (pas une roadmap aveugle).

| Semver | Thème |
|---|---|
| **1.1.0** | Stabilité + hygiène store ; **i18n EN** (app + listing) ; fixes issus closed testing / reviews |
| **1.2.0** | **Halve-It seul** |
| **Plus loin** (ordre indicatif) | Around the Clock / petits jeux → voix **ou** cible → 2e écran → thèmes pro → sync (?) |
| **iOS** | Si les données Play le justifient — **seuil à fixer plus tard** |
| **Monétisation** | Rester **gratuit sans pubs** ; tip jar / Pro cosmétique éventuel bien plus tard |

**Hors des deux premières minors post-ship :** sync cloud, IAP agressif, pubs.

## Not Doing (par phase)
- Avant gate X01 : pas de code Cricket.
- v1.2 : pas de ship Killer-only ; pas Halve-It/voix/cible/sync.
- v1.3 : pas de nouvelle capacité produit.
- v1.4 : pas de nouvelle capacité.
- v1.5 / `1.0.0` : pas iOS, pas monétisation IAP, pas pubs.
- `1.1.0`–`1.2.0` : pas sync / pubs / IAP.

## Design system & extensibilité
- Tokens + thème **`default`** ; shells portrait/paysage partagés.
- Cartes setup pour nouveaux types de jeu (Halve-It en `1.2.0`, etc.).
- Input abstrait (événements dart) pour voix/cible plus tard.

## Open Questions
- Thèmes pro : profil joueur vs thème app.
- Engineering : `GameShell` paysage vs duplications par feature.
- Seuil chiffré iOS (à caler avec Play Console).

## Context (idéation)
- Grilling Cricket v1.1, Killer+Shanghai v1.2, roadmap 1.3–1.5, post-ship (2026-10-03).
- Concurrentes : MDT (pubs, taps) ; Compteur de Fléchettes (peu de modes).
