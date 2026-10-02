# 04: Undo multi-niveaux

**What to build:** Un bouton undo est toujours visible sur l’écran de jeu. Il annule la dernière saisie et peut s’enchaîner plusieurs fois, y compris sur les volées d’autres joueurs. Après un undo, le tour revient au bon joueur. Un undo après la fin de partie rouvre la partie. L’undo retire le dernier événement de saisie du journal, puis l’état est recalculé ; aucune logique d’annulation n’est propre à un écran. Voir spec : Event sourcing, user stories 36–39.

**Blocked by:** 02 (Tracer bullet : une partie 501 par totaux).

**Status:** ready-for-agent

- [ ] Tests de façade : undo simple, undo multiple traversant plusieurs joueurs, undo après la fin de partie (la partie est rouverte, le gagnant effacé)
- [ ] Le joueur actif et les restes sont corrects après chaque undo
- [ ] Undo sans saisie à annuler : rejet typé, sans crash
- [ ] Bouton undo toujours visible dans le tiroir de saisie
