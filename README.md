# Darts

Une application Flutter pour compter les points aux **fléchettes** : une **session** enchaîne des parties de X01, de Cricket et de huit autres jeux, sur un téléphone posé près de la cible — ou sur deux, l'un qui affiche, l'autre qui saisit.

**Version web : https://thomsgodart.github.io/darts/**

> Projet personnel. Gratuit, sans publicité, sans compte : tout fonctionne hors ligne, et les scores restent sur l'appareil.

## Sommaire

- [Ce que fait l'appli](#ce-que-fait-lappli)
- [Démarrer](#démarrer)
- [Commandes utiles](#commandes-utiles)
- [Organisation du code](#organisation-du-code)
- [Comment ça marche](#comment-ça-marche)
- [Session partagée entre téléphones](#session-partagée-entre-téléphones)
- [Version web](#version-web)
- [Tests](#tests)
- [Documentation du projet](#documentation-du-projet)
- [Limites connues](#limites-connues)
- [Licence](#licence)

## Ce que fait l'appli

### Compter

- **Dix jeux** : X01, Cricket, Shanghai, Killer, Halve-It, Golf, Tour de l'horloge, Bob's 27, Count-Up et Baseball, dans n'importe quel ordre au fil d'une session.
- **X01** : départ à 170, 301, 501 ou 701 ; fin simple, double-out ou master-out ; double-in ; matchs en manches et en sets ; suggestions de checkout ; pourcentage de checkout.
- **Cricket** : standard ou cut-throat, saisi au clavier de fléchettes ou directement sur le tableau des marques.
- **Deux façons de saisir** : le total de la volée, ou fléchette par fléchette. Une volée saisie fléchette par fléchette reste affichée jusqu'à « Fin de tour ».
- **1 à 8 joueurs**, seuls ou en **équipes** (de tailles inégales si on veut), avec un **adversaire virtuel** au niveau choisi pour le X01 et le Count-Up.
- **Annuler** revient en arrière saisie par saisie, même après la fléchette gagnante.

### Autour de la partie

- **Session reprise** depuis l'accueil : elle est enregistrée à chaque saisie.
- **Rejouer** en un appui, avec l'ordre de jeu qui tourne, ou changer de joueurs et de jeu entre deux parties.
- **Historique** des sessions, avec le détail de chacune ; il se supprime session par session ou en entier.
- **Statistiques** par joueur et par jeu, sur la période choisie.
- **Portrait ou paysage** : en paysage, le score à gauche et la saisie à droite. L'écran reste allumé pendant une partie.
- **Mode écran** : le clavier se masque, le score prend tout l'écran.

### À deux téléphones

- Un téléphone **partage** la session et affiche un code à six chiffres ; l'autre la **rejoint** avec ce code.
- Le téléphone qui rejoint affiche la même partie, clavier masqué : c'est le tableau, posé près de la cible. Il peut saisir lui aussi, sauf si le premier se réserve la saisie.
- En quittant, il peut **garder une copie** de la session dans son propre historique, en disant qui est qui parmi ses joueurs.
- Rien n'est stocké en ligne, et sans réseau tout le reste marche comme avant.

## Démarrer

Il faut [Flutter](https://docs.flutter.dev/get-started/install) (canal stable, version 3.47 ou plus récente ; Dart 3.13).

```sh
git clone https://github.com/ThomsGodart/darts.git
cd darts
flutter pub get
flutter run
```

`flutter run` propose les appareils disponibles : téléphone Android branché, bureau Linux, Chrome.

L'appli n'a besoin d'aucune configuration. Seule la session partagée demande Internet.

## Commandes utiles

| Pour | Commande |
|---|---|
| Lancer les tests | `flutter test` |
| Les règles seules, en Dart pur | `flutter test test/session` |
| Vérifier le code | `flutter analyze` |
| Mettre en forme | `dart format lib test` |
| APK Android | `flutter build apk --release` |
| Site web | `flutter build web --release` |
| Régénérer le code de la base après un changement de schéma | `dart run build_runner build` |
| Essayer le partage à travers le vrai projet Supabase | `flutter test --dart-define=LIVE_SHARE=true test/share/supabase_live_test.dart` |

L'APK est écrit dans `build/app/outputs/flutter-apk/app-release.apk`. La signature et la publication sur le Play Store sont décrites dans `docs/release/android-1.0.0.md`.

## Organisation du code

```
lib/
  session/    Le domaine, en Dart pur : événements, règles des dix jeux, état, stats
  storage/    Base locale (drift / SQLite) : sessions, joueurs, réglages
  share/      Session partagée : protocole, synchronisation, transport Supabase
  setup/      Choix des joueurs, du jeu et de ses règles
  game/       L'écran de partie : tableaux de score, claviers, adversaire virtuel
  home/       Accueil
  history/    Historique et détail d'une session
  stats/      Statistiques
  settings/   Réglages, version, confidentialité
  ui/         Libellés, règles affichées et tableaux partagés entre écrans
  theme/      Couleurs, espacements, thème
test/         Les tests, rangés comme lib/
web/          Page d'accueil du site et fichiers SQLite pour le navigateur
supabase/     Configuration du projet Supabase (aucune table)
docs/         Décisions d'architecture, publication, idées
.scratch/     Spécifications et tickets, en markdown
```

Le code est en anglais, l'interface en français. Le vocabulaire du domaine est dans `CONTEXT.md`.

## Comment ça marche

### Le journal

L'état d'une session n'est jamais stocké : c'est le résultat du **journal**, la liste ordonnée de ses événements (partie lancée, fléchette lancée, volée terminée…).

`Session` (`lib/session/session_facade.dart`) est la seule entrée du domaine : elle valide une commande, ajoute un événement au journal et en déduit le nouvel état (`fold.dart`, `state.dart`). Annuler, c'est retirer le dernier événement et recalculer. Reprendre une session, c'est relire son journal.

Les écrans ne touchent ni au domaine ni au stockage : ils passent par `SessionLauncher` et `SessionController`.

### Le stockage

Les journaux, les joueurs et les réglages sont dans une base SQLite locale, par [drift](https://drift.simonbinder.eu/). Le schéma est dans `lib/storage/app_database.dart` ; après l'avoir modifié, il faut régénérer le code et ajouter une migration avec un nouveau `schemaVersion`.

### Deux choses faciles à casser

- **Les noms stockés.** Les types d'événements (`EventTypes`) et les jeux (`GameKind`) sont écrits dans la base par leur nom. En renommer un casse les journaux existants, sauf migration.
- **Les règles déjà jouées.** Le calcul de l'état doit continuer à relire les anciens journaux à l'identique. Les événements voyagent aussi entre téléphones qui partagent une session, parfois dans des versions différentes de l'appli.

## Session partagée entre téléphones

Puisqu'une session n'est que son journal, la partager revient à faire tenir le même journal par plusieurs téléphones. Ils se l'échangent par les canaux temps réel d'un projet [Supabase](https://supabase.com/), sur un canal nommé d'après le code. Il n'y a ni table, ni compte, ni serveur de jeu.

- Chaque changement du journal porte une version. Un téléphone envoie ce qui a changé ; celui qui a manqué une version redemande le journal entier, par exemple après une coupure de réseau.
- Deux saisies au même instant sur deux téléphones : une seule est gardée, l'autre disparaît de tous les écrans.
- La session est enregistrée par le téléphone qui partage. Il refuse qu'on lui réécrive les parties déjà jouées, et peut se réserver la saisie.
- Les téléphones doivent parler la même version du protocole (`ShareSignal.protocol`) ; sinon l'appli demande de se mettre à jour.

Conséquence assumée : le canal est public. Quelqu'un qui devinerait un code actif pourrait voir la partie et y saisir tant qu'elle est partagée. C'est acceptable pour une partie de fléchettes ; le détail est dans `docs/adr/0006-a-shared-session-is-its-journal-on-a-broadcast-line.md`.

L'adresse du projet et sa clé publique sont dans `lib/backend.dart`. Cette clé est faite pour être distribuée avec l'appli. Pour utiliser un autre projet, aucune préparation n'est nécessaire côté Supabase :

```sh
flutter run --dart-define=SUPABASE_URL=https://<ref>.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=<clé>
```

Une valeur vide donne une appli sans partage.

## Version web

Le site est publié sur GitHub Pages par `.github/workflows/pages.yml` : à chaque poussée sur `main`, le workflow lance les tests, compile le site et le déploie.

Dans un navigateur, SQLite tourne en WebAssembly. Deux fichiers de `web/` en dépendent :

| Fichier | Vient de | Version à suivre |
|---|---|---|
| `sqlite3.wasm` | publications GitHub de `simolus3/sqlite3.dart`, étiquette `sqlite3-<version>` | celle de `sqlite3` dans `pubspec.lock` |
| `drift_worker.js` | publications GitHub de `simolus3/drift`, étiquette `drift-<version>` | celle de `drift` dans `pubspec.lock` |

Après une montée de version de l'un de ces paquets, il faut retélécharger le fichier correspondant.

Les données du site sont gardées par le navigateur, séparément de celles de l'appli Android. Un navigateur peut partager ou rejoindre une session comme un téléphone : un ordinateur ou une tablette fait un bon tableau.

## Tests

`flutter test` lance toute la suite. Elle couvre :

- **les règles** des dix jeux : busts et checkouts, marques du Cricket, vies du Killer, matchs, équipes, adversaire virtuel, avec des tests de propriétés sur les totaux possibles ;
- **le journal** : chaque événement s'écrit et se relit, y compris ceux des anciennes versions ;
- **le stockage** : les mêmes tests de contrat passent sur la base en mémoire et sur SQLite ;
- **le partage** : deux téléphones sur un réseau simulé, avec coupures, saisies simultanées, messages malformés et versions incompatibles ;
- **les écrans** : des sessions entières jouées à travers l'interface, en portrait et en paysage.

Le test du partage à travers le vrai projet Supabase n'est lancé que sur demande (voir [Commandes utiles](#commandes-utiles)).

## Documentation du projet

| Fichier | Contenu |
|---|---|
| `CONTEXT.md` | Le vocabulaire du domaine : termes du code et de l'interface. |
| `docs/adr/` | Les décisions difficiles à défaire, avec leur raison. |
| `docs/release/` | Fiche Play Store, formulaire Data safety, étapes de publication Android. |
| `.scratch/<fonctionnalité>/` | Spécifications et tickets, en markdown (`docs/agents/issue-tracker.md`). |
| `CLAUDE.md` | Les consignes données à l'assistant de code qui travaille sur le projet. |

## Limites connues

- **Session partagée** : couverte par les tests automatiques et essayée entre deux clients à travers Supabase, mais pas encore éprouvée sur deux vrais téléphones pendant une soirée. La liste de ce qu'il reste à vérifier est dans `.scratch/shared-session/issues/02-device-validation.md`.
- **Pas d'identité commune entre appareils** : un joueur n'existe que dans le catalogue de son téléphone. La copie gardée par le téléphone qui rejoint rapproche les joueurs par leur nom.
- **Version web** : compilée et ouverte dans Chrome ; pas essayée sur d'autres navigateurs ni sur une partie entière.
- **Rapports de plantage** : le code est prêt (Crashlytics, en production seulement), mais aucun projet Firebase n'est branché.
- **iOS, macOS, Windows, Linux** : les projets existent, mais seul Android est visé.

## Licence

Aucune licence n'est attachée à ce dépôt pour l'instant : le code est consultable, mais sa réutilisation n'est pas autorisée par défaut.
