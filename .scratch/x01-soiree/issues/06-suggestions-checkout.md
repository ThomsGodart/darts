# 06: Suggestions de checkout

**What to build:** Quand le reste du joueur actif est ≤ 170 et finissable, une suggestion de checkout de 1 à 3 fléchettes s’affiche (ex. 170 → T20 T20 Bull). Elle tient compte du nombre de fléchettes restantes dans la volée et se met à jour à chaque fléchette en mode fléchettes. Les suggestions viennent d’une table statique de 2 à 170 pour le Double-out ; en Straight-out, la suggestion est le plus court chemin quelconque. Pour un reste impossible, aucune suggestion ne s’affiche. Voir spec : Checkout, user stories 33, 34.

**Blocked by:** 03 (Règles Double-out complètes), 05 (Saisie fléchette par fléchette).

**Status:** ready-for-agent

- [x] Tests de façade sur un échantillon : 170, 100, 40, 3, 2 en Double-out ; reste impossible (ex. 169) → aucune suggestion
- [x] Tests de façade : suggestion recalculée après une fléchette (moins de fléchettes restantes)
- [x] Tests de façade : suggestion en Straight-out
- [x] UI : suggestion visible sur le scoreboard (token checkout possible)

## Comments

- 2026-10-03 — Implémenté : `GameState.checkoutSuggestion`, à partir du reste en direct et des fléchettes restantes de la volée.
  - Au lieu d’une table saisie à la main (169 lignes, risque de coquilles), les routes sont **calculées puis mémorisées** : le moins de fléchettes possible, puis les fléchettes préférées (simples, T20/T19…, finish sur D16/D20/D8…).
  - Le résultat se comporte comme une table statique. Un test vérifie que les 2–170 finissables ont une route valide et la plus courte, et que 159/162/163/165/166/168/169 n’en ont pas.
  - Routes proches des charts usuels (170 T20 T20 Bull, 141 T20 T19 D12, 81 T19 D12, 61 25 D18…), sans les recopier exactement (ex. 99 → T19 2 D20).
  - UI : pastille en couleur `checkout` sous le reste du joueur actif.
- 2026-10-03 — Suite à la code review :
  - Plus aucune suggestion au-dessus de 170, Straight-out compris (US 33).
  - En Straight-out, la route est appelée de la plus grosse fléchette à la plus petite.
  - Table Double-out 2–170 figée dans `test/soiree/checkout_table.txt` (régénérer avec `UPDATE_CHECKOUT_TABLE=1 flutter test test/soiree/checkout_table_test.dart`).
  - Le test widget vérifie seulement que la suggestion s’affiche.
