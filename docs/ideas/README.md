# Ideas — convention de versioning

## Fichiers

| Path | Rôle |
|---|---|
| `darts-scoreboard-ui-first.md` | **Index vivant** (roadmap + liens). On peut le mettre à jour, mais chaque jalon majeur doit laisser une archive. |
| `archive/YYYY-MM-DD-*.md` | **Snapshots immuables** — ne pas éditer ; en créer un nouveau si le narratif change. |
| `../../.scratch/<jalon>/spec.md` | **Contrat d’implémentation** par jalon (source de vérité pour le build). |

## Règle

1. Avant de réécrire l’index, copier l’état courant vers `archive/YYYY-MM-DD-<slug>.md`.
2. Tout jalon pré-ship (v1.1 … v1.5) a un dossier `.scratch/…` — **pas seulement une puce dans l’idea**.
3. Les tickets vivent sous `.scratch/<jalon>/issues/`.

## Archives

- [2026-10-02 — one-pager X01 soirée](archive/2026-10-02-x01-soiree-one-pager.md) (git `d57c1c5`)
- [2026-10-03 — roadmap soirée → Play](archive/2026-10-03-roadmap-soiree-play.md)
