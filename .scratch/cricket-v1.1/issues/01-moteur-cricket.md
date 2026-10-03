# 01: Moteur Cricket (Standard + Cut-Throat)

**What to build:** Façade / fold Dart pur pour une partie Cricket : marks 15–20+Bull, fermeture à 3, points Standard vs Cut-Throat, chiffre mort, condition de victoire, sudden death (premier Bull si board mort et scores égaux), fin de visite (3 fléchettes ou pass), MPR / points / rounds exposés dans l’état. Pas d’UI. Les commandes s’appuient sur des fléchettes (`Dart`) déjà modélisées ; hors-cible = 0 mark. Voir spec : Rules, user stories 7–11, 16.

**Blocked by:** Validation humaine v1 X01 en soirée (« on garde ça »).

**Status:** ready-for-human

- [ ] Config `CricketConfig` (variant Standard | CutThroat) + état immuable (marks par joueur/chiffre, points, visite en cours, finished/winner, sudden death)
- [ ] Fold : throw dart, end visit early, undo last dart/visit-end
- [ ] Tests façade : Standard scoring, Cut-Throat scoring, dead number, win both variants, sudden death, MPR/rounds, undo
- [ ] Aucun import Flutter / Drift

## Comments

- Gate produit : ne pas coder tant que 2 soirées X01 n’ont pas validé la v1.
