# 05: Grille lisible de loin

**What to build:** La grille Cricket se lit à 2–3 m sur un téléphone posé.
- Nouveaux tokens de thème : couleur de marque, chiffre fermé, chiffre mort, taille des marques et des points. Rien en dur dans les widgets.
- La colonne du joueur actif est mise en avant, et les chiffres morts sont grisés.
- Avec 5 à 8 joueurs, la grille reste lisible : colonnes compactes, sans défilement horizontal sur un écran de 6".

Voir spec : US 18–20 ; Further Notes.

**Blocked by:** 02 (Tracer bullet : une partie de Cricket Standard).

**Status:** ready-for-agent

- [x] Tokens de grille dans `DartsTokens` et le thème `default` ; aucune couleur ni taille en dur dans la grille
- [x] Test widget : 8 joueurs sur un écran de téléphone, sans débordement
- [ ] Écran statique vérifié à la main à 2–3 m (à faire sur appareil)

## Comments

- 2026-10-03 — Implémenté :
  - Tokens `cricketMark`, `cricketClosed`, `cricketDead`, `cricketMarkFontSize` et `cricketPointsFontSize` dans `DartsTokens` et le thème `default`. La classe de tokens est régénérée depuis une seule liste de champs.
  - Grille : colonnes joueurs en largeur partagée, noms tronqués, marques et points en `FittedBox`.
  - Couleur selon l’état : ouvert, fermé, chiffre mort barré et grisé.
  - Colonne du joueur actif surlignée.
  - Test widget : 8 joueurs aux noms longs sur un 6,1" (393 dp) sans débordement.
- Reste à faire sur appareil : lecture à 2–3 m.
- 2026-10-03 — Suite à la code review : surlignage de la colonne active via un token `cricketActiveColumn`, plus d’alpha en dur.
