# 01: Partage par code + mode écran

**What to build:** Une session se partage sous un code ; un autre téléphone la rejoint, l’affiche et peut y saisir. Le clavier de saisie se masque pour un affichage plein écran.

**Blocked by:** None.

**Status:** ready-for-human

- [x] `SessionShare` : journal échangé par deltas versionnés, rattrapage après coupure, convergence sur saisies simultanées
- [x] Transport Supabase Realtime broadcast (identifiants intégrés, surchargables par `--dart-define`) ; transport mémoire pour les tests
- [x] Partie : icône de partage (code, appareils qui ont rejoint, arrêt), icône masquer/afficher le clavier
- [x] Accueil : « Rejoindre une session » ; l’invité ouvre en mode écran
- [x] Session terminée sur un appareil : la partie se ferme sur les autres
- [x] Permission `INTERNET` dans le manifest principal ; privacy + Data safety mises à jour
- [x] Vérifié en réel contre le projet Supabase (deux clients, hôte + invité)

## Comments

- 2026-10-06: agent — voir `docs/adr/0006`. Validation sur deux vrais téléphones : ticket 02.
