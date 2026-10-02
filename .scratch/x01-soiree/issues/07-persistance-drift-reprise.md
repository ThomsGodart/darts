# 07: Persistance drift + reprise

**What to build:** Une partie interrompue (app tuée, téléphone verrouillé, crash) reprend exactement où elle en était. À l’ouverture, l’app propose de reprendre la soirée en cours. Le journal d’événements est persisté en SQLite via drift, dans une table d’événements de soirée (id soirée, séquence, type, payload JSON, horodatage). Chaque commande acceptée ajoute son événement de façon atomique, et l’undo supprime le dernier. L’implémentation drift se branche sur le port journal posé au ticket 02. Voir spec : Persistance, user stories 44, 45.

**Blocked by:** 02 (Tracer bullet : une partie 501 par totaux).

**Status:** ready-for-agent

- [ ] Test de façade : dérouler une soirée sur le journal mémoire, reconstruire une façade sur le même journal → état identique
- [ ] Même test sur le journal drift avec une base SQLite en mémoire
- [ ] Un undo est persistant : après rechargement, l’événement annulé a disparu
- [ ] À l’ouverture, une soirée non terminée est proposée à la reprise
- [ ] Fonctionne entièrement offline
