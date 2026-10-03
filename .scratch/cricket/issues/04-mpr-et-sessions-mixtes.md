# 04: MPR + sessions mixtes dans les stats

**What to build:** La stat du Cricket est le **MPR** : les marques sur 15–20 et Bull (celles qui ferment comme celles qui scorent, mortes comprises), divisées par le nombre de volées jouées. La volée gagnante compte pour une volée entière.
- Le MPR s’affiche par joueur pendant la partie et dans le panneau de fin de partie.
- Sur la session, deux stats séparées : MPR sur les parties de Cricket uniquement, moyenne 3 fléchettes sur les parties X01 uniquement. Une colonne n’apparaît que si le joueur a joué ce type.
- L’historique indique le type de chaque partie (« 501 DO », « Cricket », « Cut-Throat ») et sa stat.
- « Changer… » permet de passer d’un X01 à un Cricket et inversement.

Voir spec : US 4, 22–24 ; Implementation Decisions (MPR).

**Blocked by:** 02 (Tracer bullet : une partie de Cricket Standard).

**Status:** ready-for-agent

- [x] Tests de façade : MPR d’une partie (dont volée gagnante incomplète et marques sur chiffre mort)
- [x] Tests de façade : session mixte, MPR calculé sur les seules parties Cricket et moyenne sur les seules parties X01, pour chaque joueur
- [x] Contrat de repository : l’historique d’une session mixte expose les bons gagnants, MPR et moyennes
- [x] UI : MPR en jeu et en fin de partie ; libellés de type dans l’historique ; changement de type via « Changer… »

## Comments

- 2026-10-03 — Implémenté :
  - `CricketScore.marksHit` (toutes les marques sur 15–20 et Bull, mortes comprises).
  - `CricketGame.marksPerRound` : la volée en cours compte comme un tour, et la volée gagnante comme un tour entier.
  - `SessionState.marksPerRoundOf` porte sur les seules parties Cricket ; `averageOf` reste sur les seules parties X01.
  - UI :
    - Ligne « MPR » sous la grille.
    - Panneau de fin de partie : pts, MPR et MPR de session.
    - Historique : « Stats de la session » avec « moy. · MPR » selon les types joués, et pts + MPR par partie de Cricket.
  - « Changer… » passe du X01 au Cricket, ce que couvre un test widget.
