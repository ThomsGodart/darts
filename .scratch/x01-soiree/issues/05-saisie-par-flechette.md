# 05: Saisie fléchette par fléchette

**What to build:** Le joueur peut basculer la volée en cours en mode fléchette par fléchette.
- Chaque fléchette se saisit avec un secteur de 1 à 20 et simple, double ou triple, ou bien outer bull 25, bull 50 ou raté.
- Les fléchettes de la volée en cours s’affichent.
- La volée se termine automatiquement à la 3e fléchette, au bust ou au checkout ; le checkout en Double-out exige un double ou un bull.
- La volée suivante revient en mode total.
- Totaux et fléchettes se mélangent dans une même partie. La moyenne compte les fléchettes réellement lancées.
- L’undo annule une fléchette à la fois.

Voir spec : Mode fléchette par fléchette, Moteur X01, user stories 18, 19, 53.

**Blocked by:** 03 (Règles Double-out complètes).

**Status:** ready-for-agent

- [ ] Tests de façade : volée par fléchettes complète, bust en cours de volée (fin immédiate), checkout sur double, refus d’un checkout sur simple en Double-out (bust)
- [ ] Tests de façade : partie mélangeant totaux et fléchettes, moyenne exacte (bust en 2 fléchettes = 2 fléchettes comptées)
- [ ] Tests de façade : l’undo retire une fléchette de la volée en cours
- [ ] UI : bascule pour une volée, sélecteur secteur/multiplicateur/bull/raté, retour au mode total à la volée suivante
