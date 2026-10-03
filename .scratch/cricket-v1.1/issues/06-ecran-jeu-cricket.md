# 06: Écran de jeu Cricket (shell)

**What to build:** Brancher matrice + grille dans le flux de partie : pas de bannière texte ; wakelock + haptique au changement de joueur ; panneau de fin avec gagnant, MPR, points, rounds, Rejouer / Changer… / Terminer (même chorégraphie que X01). GameScreen (ou dérivé) choisit le shell selon le kind de partie. Voir spec : user stories 14–16 ; Solution.

**Blocked by:** 02, 03, 05

**Status:** ready-for-human

- [ ] Navigation setup Cricket → écran jeu Cricket
- [ ] Highlight + haptique + wakelock ; pas de TurnBanner en Cricket
- [ ] Game over panel stats Cricket
- [ ] Tests flux : partie courte jusqu’au gagnant ; undo checkout/sudden death si applicable

## Comments
