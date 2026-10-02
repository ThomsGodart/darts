# 07: Persistance drift + reprise

**What to build:** Une partie interrompue (app tuée, téléphone verrouillé, crash) reprend exactement où elle en était. À l’ouverture, l’app propose de reprendre la soirée en cours. Le journal d’événements est persisté en SQLite via drift, dans une table d’événements de soirée (id soirée, séquence, type, payload JSON, horodatage). Chaque commande acceptée ajoute son événement de façon atomique, et l’undo supprime le dernier. L’implémentation drift se branche sur le port journal posé au ticket 02. Voir spec : Persistance, user stories 44, 45.

**Blocked by:** 02 (Tracer bullet : une partie 501 par totaux).

**Status:** ready-for-agent

- [x] Test de façade : dérouler une soirée sur le journal mémoire, reconstruire une façade sur le même journal → état identique
- [x] Même test sur le journal drift avec une base SQLite en mémoire
- [x] Un undo est persistant : après rechargement, l’événement annulé a disparu
- [x] À l’ouverture, une soirée non terminée est proposée à la reprise
- [x] Fonctionne entièrement offline

## Comments

- 2026-10-02 — Implémenté :
  - Port `SoireeRepository` (create / latest / flush) + extension `resumable()`, avec une implémentation mémoire (tests) et `DriftSoireeRepository`.
  - Tables `soirees` + `soiree_events` (soireeId, seq, type, payload JSON, recordedAt).
  - Le journal drift lit depuis la mémoire et écrit dans la base en arrière-plan, via une file d’écritures ordonnée. L’undo supprime la ligne du dernier événement.
  - Codec d’événements à tags stables (`event_codec.dart`).
  - Un même contrat de tests tourne sur les deux implémentations (mémoire et SQLite en mémoire).
  - Accueil : bouton « Reprendre la partie » pour la dernière soirée dont la partie est en cours.
- Limite connue : une écriture non encore terminée au moment où l’app est tuée est perdue (au plus le dernier événement). Un `flush()` à la mise en arrière-plan de l’app réduirait encore ce risque.
- « Soirée non terminée » = dernière soirée avec une partie en cours, en attendant l’événement de fin de soirée (ticket 09).
- Non vérifié sur appareil (build Android/iOS).
- 2026-10-02 — Suite à la code review :
  - Après un premier échec d’écriture, plus rien n’est écrit : le journal stocké reste un préfixe cohérent, et `flush()` remonte l’erreur.
  - Écriture forcée quand l’app passe en pause ou est détachée (`AppLifecycleListener` sur l’accueil).
  - Le spec documente le compromis « écriture en arrière-plan, pas atomique ».
