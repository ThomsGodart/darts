# 02: Tracer bullet : une partie 501 par totaux

**What to build:** Depuis l’accueil, on lance une partie 501 en Straight-out avec deux joueurs fixes (setup réel au ticket 08). L’écran de jeu affiche d’abord le scoreboard : nom du joueur actif et reste en très gros en haut, autres joueurs avec leur reste et leur dernière volée en liste compacte. En bas, un tiroir de saisie propose une rangée de quick-scores (26, 41, 45, 60, 81, 85, 100, 140, 180), un pavé numérique pour un total de 0 à 180 et un bouton « 0 ». Après chaque saisie, le tour passe sans confirmation. La partie se termine quand un joueur atteint exactement 0. Le joueur passe en Straight-out sous 0 : la volée compte 0 (règles complètes au ticket 03).

Ce ticket pose la **façade `Soirée`** en Dart pur, sans Flutter ni DB. Elle reçoit des commandes, expose un état immuable et s’appuie sur un journal d’événements en mémoire dont l’état est calculé par fold. Un notifier fin relie la façade à l’UI, et les widgets n’appellent jamais le moteur directement. Voir spec : Implementation Decisions (Façade, Event sourcing, Moteur X01, UI), user stories 14, 15, 17, 20, 22, 29–32, 53.

**Blocked by:** 01 (App shell offline-first + thème `default`).

**Status:** ready-for-agent

- [ ] Façade `Soirée` en Dart pur : commandes démarrer une partie / soumettre une volée par total ; état exposé : joueurs, joueur actif, restes, dernière volée, partie terminée + gagnant
- [ ] Journal d’événements derrière un port abstrait, implémentation mémoire
- [ ] Les tests de façade se lisent comme une partie (ex. deux joueurs, 501, déroulé jusqu’au gagnant)
- [ ] Écran de jeu scoreboard-first, quick-scores en un tap, pavé numérique + valider, bouton « 0 »
- [ ] Styles exclusivement via les tokens du thème `default`
- [ ] Smoke test widget : un tap sur un quick-score change le reste affiché
