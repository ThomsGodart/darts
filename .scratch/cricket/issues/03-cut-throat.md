# 03: Cut-Throat

**What to build:** Dans le setup, le Cricket propose « Standard » ou « Cut-Throat ».
- En Cut-Throat, les marques en trop sur un chiffre fermé donnent sa valeur en points à **chaque adversaire** qui ne l’a pas fermé.
- On gagne dès qu’on a tout fermé avec **au plus** autant de points que chaque adversaire.
- « Rejouer » garde la variante.
- L’écran rappelle la variante en cours, pour qu’on sache si les points sont bons ou mauvais.

Voir spec : US 2, 3, 13, 16.

**Blocked by:** 02 (Tracer bullet : une partie de Cricket Standard).

**Status:** ready-for-agent

- [ ] Tests de façade : points attribués aux adversaires non fermés, pas à ceux qui ont fermé
- [ ] Tests de façade : victoire Cut-Throat (égalité comprise) ; tout fermer avec plus de points qu’un adversaire ne gagne pas
- [ ] Tests de façade : « Rejouer » garde Cut-Throat ; la variante survit à une relance
- [ ] Setup : choix Standard / Cut-Throat ; variante visible pendant la partie
