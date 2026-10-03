# 01: GameShell paysage + X01

**What to build:** Les parties X01 acceptent l’orientation libre. En paysage (ou largeur wide), l’écran utilise un shell unique **état à gauche | saisie à droite** ; en portrait, le comportement actuel est préservé. Une rotation mid-visite ne perd pas la saisie. Wakelock inchangé. Aucune nouvelle capacité produit.

**Blocked by:** None (can start immediately) — requires v1.2 shipped.

**Status:** resolved

- [x] Shell de layout jeu (slots état / saisie) branché sur X01
- [x] Portrait = stack actuel sans régression fonctionnelle
- [x] Paysage/wide = split ~50/50 ou 40/60 sans overflow bloquant sur téléphone courant
- [x] Rotation mid-visite conserve controller / visite en cours
- [x] Widget tests surface portrait + paysage (prior art game screen tests)
