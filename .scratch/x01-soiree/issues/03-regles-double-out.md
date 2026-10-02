# 03: Règles Double-out complètes

**What to build:** Les parties respectent les règles X01 officielles.
- 501 ou 301, Double-out activé par défaut, Straight-out possible.
- Une volée est un bust si elle passe le reste sous 0, ou, en Double-out, à 1, ou à 0 sans finir sur un double. Un bust remet le reste à sa valeur de début de volée, passe le tour et est clairement signalé à l’écran.
- Les totaux impossibles en 3 fléchettes (179, 178, 176, 175, 173, 172, 169, 166, 163) sont refusés.
- En Double-out, les finishes impossibles (169, 168, 166, 165, 163, 162, 159, et tout reste > 170) ne peuvent pas terminer une partie.
- En mode total, quand une volée amène le reste à 0, l’app demande « combien de fléchettes ? » (1, 2 ou 3). Le checkout est présumé valide s’il est atteignable en finissant sur un double.
- La moyenne 3 fléchettes de chaque joueur s’affiche pendant la partie. Une volée bust compte 0 point et 3 fléchettes.

Les rejets passent par un résultat typé de la façade, sans changer l’état. Voir spec : Implementation Decisions (Moteur X01, Validation des totaux), user stories 7, 8, 16, 23–29, 35.

**Blocked by:** 02 (Tracer bullet : une partie 501 par totaux).

**Status:** ready-for-agent

- [ ] Tests de façade : 501 et 301, en Double-out et en Straight-out
- [ ] Tests de façade : les trois cas de bust
- [ ] Tests de façade : rejet des totaux impossibles et des checkouts impossibles, avec l’état inchangé
- [ ] Tests de façade : checkout avec nombre de fléchettes et moyenne exacte (ex. 180, 180, 141 en 3 fléchettes → moyenne 167)
- [ ] UI : signal bust visible (token bust), dialog « combien de fléchettes ? » uniquement au checkout
- [ ] UI : moyenne 3 fléchettes affichée par joueur
