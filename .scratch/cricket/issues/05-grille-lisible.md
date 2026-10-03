# 05: Grille lisible de loin

**What to build:** La grille Cricket se lit à 2–3 m sur un téléphone posé.
- Nouveaux tokens de thème : couleur de marque, chiffre fermé, chiffre mort, taille des marques et des points. Rien en dur dans les widgets.
- La colonne du joueur actif est mise en avant, et les chiffres morts sont grisés.
- Avec 5 à 8 joueurs, la grille reste lisible : colonnes compactes, sans défilement horizontal sur un écran de 6".

Voir spec : US 18–20 ; Further Notes.

**Blocked by:** 02 (Tracer bullet : une partie de Cricket Standard).

**Status:** ready-for-agent

- [ ] Tokens de grille dans `DartsTokens` et le thème `default` ; aucune couleur ni taille en dur dans la grille
- [ ] Test widget : 8 joueurs sur un écran de téléphone, sans débordement
- [ ] Écran statique vérifié à la main à 2–3 m (à faire sur appareil)
