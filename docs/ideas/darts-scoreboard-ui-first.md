# Darts Points Counter — Index roadmap

> Index vivant. Historique figé : [`archive/`](archive/) — convention : [`README.md`](README.md).

## Problem Statement
Soirée fléchettes sur **un téléphone partagé**, plus rapide/lisible que MyDartTraining, **offline**, puis **Play** (gratuit, sans pubs, sans compte).

## Jalons pré-ship (labels internes)

| Jalon | Spec | Notes |
|---|---|---|
| **v1** X01 Session | [`.scratch/x01-soiree/spec.md`](../../.scratch/x01-soiree/spec.md) | One-pager d’origine : [archive/2026-10-02-…](archive/2026-10-02-x01-soiree-one-pager.md) |
| **v1.1** Cricket | [`.scratch/cricket-v1.1/spec.md`](../../.scratch/cricket-v1.1/spec.md) | + [issues/](../../.scratch/cricket-v1.1/issues/) |
| **v1.2** Killer + Shanghai | [`.scratch/killer-shanghai-v1.2/spec.md`](../../.scratch/killer-shanghai-v1.2/spec.md) | Ship des **deux** ensemble |
| **v1.3** Paysage + Settings stub | [`.scratch/landscape-v1.3/spec.md`](../../.scratch/landscape-v1.3/spec.md) | Pas de nouvelle capacité |
| **v1.4** Hygiène UI/UX | [`.scratch/ui-hygiene-v1.4/spec.md`](../../.scratch/ui-hygiene-v1.4/spec.md) | Aligné audit Rams `DESIGN-IS-2026-10-03/` |
| **v1.5** Ship Play | [`.scratch/play-ship-v1.5/spec.md`](../../.scratch/play-ship-v1.5/spec.md) | → semver **`1.0.0`** |

Snapshot narratif complet du 2026-10-03 : [archive/2026-10-03-roadmap-soiree-play.md](archive/2026-10-03-roadmap-soiree-play.md).

## Versioning produit
- Jalons **v1…v1.5** = pré-ship (`.scratch/`).
- Premier Play prod = **`1.0.0`**.
- Puis **`1.1.0`** (stabilité + EN), **`1.2.0`** (Halve-It), … ; **`2.0.0`** = changement de promesse (ex. sync).

## Post-shipping (après `1.0.0`)

Priorisation : Crashlytics + reviews ; jeux en file.

| Semver | Thème |
|---|---|
| **1.1.0** | Stabilité + hygiène store ; i18n EN |
| **1.2.0** | Halve-It seul |
| Plus loin | Around the Clock / petits jeux → voix ou cible → 2e écran → thèmes pro → sync (?) |
| iOS | Si données Play le justifient (seuil plus tard) |
| Monétisation | Rester gratuit sans pubs |

## Assumptions (gates)
- [ ] 2 soirées X01 sans MDT → code Cricket
- [ ] Cricket pastilles OK à distance
- [ ] Killer + Shanghai joués en soirée
- [ ] 4 jeux en paysage une soirée
- [ ] Vote polish « store-ready vs MDT »
- [ ] Closed testing 1 semaine + 2 soirées cercle élargi

## Open Questions
- Thèmes pro : profil vs app
- `GameShell` paysage vs duplications
- Seuil iOS chiffré
