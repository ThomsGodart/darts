# 06: Suggestions de checkout

**What to build:** Quand le reste du joueur actif est ≤ 170 et finissable, une suggestion de checkout de 1 à 3 fléchettes s’affiche (ex. 170 → T20 T20 Bull). Elle tient compte du nombre de fléchettes restantes dans la volée et se met à jour à chaque fléchette en mode fléchettes. Les suggestions viennent d’une table statique de 2 à 170 pour le Double-out ; en Straight-out, la suggestion est le plus court chemin quelconque. Pour un reste impossible, aucune suggestion ne s’affiche. Voir spec : Checkout, user stories 33, 34.

**Blocked by:** 03 (Règles Double-out complètes), 05 (Saisie fléchette par fléchette).

**Status:** ready-for-agent

- [ ] Tests de façade sur un échantillon : 170, 100, 40, 3, 2 en Double-out ; reste impossible (ex. 169) → aucune suggestion
- [ ] Tests de façade : suggestion recalculée après une fléchette (moins de fléchettes restantes)
- [ ] Tests de façade : suggestion en Straight-out
- [ ] UI : suggestion visible sur le scoreboard (token checkout possible)
