# 04: Undo multi-niveaux

**What to build:** Un bouton undo est toujours visible sur l’écran de jeu. Il annule la dernière saisie et peut s’enchaîner plusieurs fois, y compris sur les volées d’autres joueurs. Après un undo, le tour revient au bon joueur. Un undo après la fin de partie rouvre la partie. L’undo retire le dernier événement de saisie du journal, puis l’état est recalculé ; aucune logique d’annulation n’est propre à un écran. Voir spec : Event sourcing, user stories 36–39.

**Blocked by:** 02 (Tracer bullet : une partie 501 par totaux).

**Status:** ready-for-agent

- [x] Tests de façade : undo simple, undo multiple traversant plusieurs joueurs, undo après la fin de partie (la partie est rouverte, le gagnant effacé)
- [x] Le joueur actif et les restes sont corrects après chaque undo
- [x] Undo sans saisie à annuler : rejet typé, sans crash
- [x] Bouton undo toujours visible dans le tiroir de saisie

## Comments

- 2026-10-02 — Implémenté : `Soiree.undo()` / `canUndo`.
  - Le journal gagne `removeLast()`. L’état est recalculé par fold complet.
  - Seules les saisies de la partie courante s’annulent : la partie elle-même n’est jamais annulée.
  - Undo toujours visible dans le tiroir (désactivé sans saisie à annuler).
  - « Annuler le checkout » sur le panneau de fin de partie.
  - 52 tests verts.
