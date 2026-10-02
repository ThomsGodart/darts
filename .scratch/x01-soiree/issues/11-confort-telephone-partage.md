# 11: Confort téléphone partagé

**What to build:** À chaque changement de tour, une bannière affiche le nom du joueur suivant et le téléphone vibre, pour que celui qui le prend sache que c’est à lui. L’écran ne se met pas en veille pendant une partie. En build debug seulement, un compteur de taps par volée sert à mesurer l’hypothèse ≤ 2 taps en moyenne par volée. Voir spec : UI, Further Notes, user stories 21, 51.

**Blocked by:** 02 (Tracer bullet : une partie 501 par totaux).

**Status:** ready-for-agent

- [ ] Bannière + haptique au changement de joueur, sans bloquer la saisie suivante
- [ ] Wakelock actif pendant une partie, relâché en dehors
- [ ] Compteur de taps (moyenne de taps par volée) visible uniquement en debug
- [ ] Aucune pub ni popup intrusive
