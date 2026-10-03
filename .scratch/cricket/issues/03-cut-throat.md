# 03: Cut-Throat

**What to build:** Dans le setup, le Cricket propose « Standard » ou « Cut-Throat ».
- En Cut-Throat, les marques en trop sur un chiffre fermé donnent sa valeur en points à **chaque adversaire** qui ne l’a pas fermé.
- On gagne dès qu’on a tout fermé avec **au plus** autant de points que chaque adversaire.
- « Rejouer » garde la variante.
- L’écran rappelle la variante en cours, pour qu’on sache si les points sont bons ou mauvais.

Voir spec : US 2, 3, 13, 16.

**Blocked by:** 02 (Tracer bullet : une partie de Cricket Standard).

**Status:** ready-for-agent

- [x] Tests de façade : points attribués aux adversaires non fermés, pas à ceux qui ont fermé
- [x] Tests de façade : victoire Cut-Throat (égalité comprise) ; tout fermer avec plus de points qu’un adversaire ne gagne pas
- [x] Tests de façade : « Rejouer » garde Cut-Throat ; la variante survit à une relance
- [x] Setup : choix Standard / Cut-Throat ; variante visible pendant la partie

## Comments

- 2026-10-03 — Implémenté :
  - `CricketVariant.cutThroat` : les marques en trop donnent les points à chaque adversaire encore ouvert, et le moins de points gagne (égalité comprise).
  - Le setup propose Standard / Cut-Throat.
  - La grille rappelle la variante et la règle de victoire.
  - L’historique affiche « Cut-Throat ».
  - « Rejouer » et la reprise après relance gardent la variante.
