# 02: Tracer bullet : une partie 501 par totaux

**What to build:** Depuis l’accueil, on lance une partie 501 en Straight-out avec deux joueurs fixes (setup réel au ticket 08). L’écran de jeu affiche d’abord le scoreboard : nom du joueur actif et reste en très gros en haut, autres joueurs avec leur reste et leur dernière volée en liste compacte. En bas, un tiroir de saisie propose une rangée de quick-scores (26, 41, 45, 60, 81, 85, 100, 140, 180), un pavé numérique pour un total de 0 à 180 et un bouton « 0 ». Après chaque saisie, le tour passe sans confirmation. La partie se termine quand un joueur atteint exactement 0. Le joueur passe en Straight-out sous 0 : la volée compte 0 (règles complètes au ticket 03).

Ce ticket pose la **façade `Soirée`** en Dart pur, sans Flutter ni DB. Elle reçoit des commandes, expose un état immuable et s’appuie sur un journal d’événements en mémoire dont l’état est calculé par fold. Un notifier fin relie la façade à l’UI, et les widgets n’appellent jamais le moteur directement. Voir spec : Implementation Decisions (Façade, Event sourcing, Moteur X01, UI), user stories 14, 15, 17, 20, 22, 29–32, 53.

**Blocked by:** 01 (App shell offline-first + thème `default`).

**Status:** ready-for-agent

- [x] Façade `Soirée` en Dart pur : commandes démarrer une partie / soumettre une volée par total ; état exposé : joueurs, joueur actif, restes, dernière volée, partie terminée + gagnant
- [x] Journal d’événements derrière un port abstrait, implémentation mémoire
- [x] Les tests de façade se lisent comme une partie (ex. deux joueurs, 501, déroulé jusqu’au gagnant)
- [x] Écran de jeu scoreboard-first, quick-scores en un tap, pavé numérique + valider, bouton « 0 »
- [x] Styles exclusivement via les tokens du thème `default`
- [x] Smoke test widget : un tap sur un quick-score change le reste affiché

## Comments

- 2026-10-02 — Implémenté : façade `Soiree` (Dart pur) + `InMemoryJournal`, events `GameStarted` (avec `X01Config` : score de départ + `OutRule.straight`) et `VisitTotalSubmitted`, état par fold ; `SoireeController` (ChangeNotifier) injecté depuis `DartsApp` ; écran de jeu scoreboard-first, quick-scores, pavé + OK, « 0 / raté ». 22 tests verts, analyze propre.
- Code review (standards + spec) appliquée : config X01 enregistrée dans l’event, refus d’un `startGame` pendant une partie en cours ou avec un score de départ invalide, construction de la façade sortie des widgets, getters `activeScore` / `waitingInTurnOrder`.
- Laissé pour plus tard : dernière volée du joueur actif non affichée (US 32, petit), graisses / espacements encore en dur (hors règle « couleurs et tailles du scoreboard »), panneau de fin de partie minimal (le vrai écran est au ticket 09).
- Pour le ticket 03 : ajouter `OutRule.double` (défaut du spec) et brancher les règles de bust dans le fold.
