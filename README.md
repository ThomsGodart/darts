# Darts

Offline darts scorer for a shared phone: a **session** chains games of X01, Cricket, Shanghai and Killer, with undo, resume and a history. Flutter, Android first. The UI is in French; code and docs are in English.

## Quick start

```sh
flutter pub get
flutter run
```

The app works with no configuration. Two integrations are optional and off by default:

- **Supabase**: pass `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`; without them the app runs offline (`lib/backend.dart`).
- **Crashlytics**: release builds only, once Firebase options are configured (`lib/crash_reporting.dart`).

## Commands

| Command | What it does |
| --- | --- |
| `flutter test` | Runs the whole suite |
| `flutter test test/session` | Domain tests only: plain Dart, no widgets |
| `flutter analyze` | Static analysis |
| `dart format lib test` | Formats the code |
| `dart run build_runner build` | Regenerates `lib/storage/app_database.g.dart` after a Drift schema change |

Building and signing the Android release is described in `docs/release/android-1.0.0.md`.

## Architecture

The state of a session is never stored: it is a fold over its **journal**, an ordered list of events.

- `lib/session/`: the domain, plain Dart. `Session` (`session_facade.dart`) is the single entry point: it validates a command, appends an event to the journal and folds it into the new state (`fold.dart`, `state.dart`). Undo removes the last event and folds again. `event_codec.dart` is the storage format of events.
- `lib/storage/`: Drift (SQLite) adapters for the session repository and the player catalog. Tests use the in-memory adapters from `lib/session/`.
- `lib/session_launcher.dart`, `lib/session_controller.dart`: what widgets talk to. They never touch the domain or storage directly.
- `lib/setup/`, `lib/game/`, `lib/history/`, `lib/home/`, `lib/settings/`: one folder per screen. Every game input is built on `lib/game/input_pane.dart`.
- `lib/ui/`: labels and stats shared by several screens. `lib/theme/`: the `default` theme, its `DartsTokens` and the `DartsSpace` spacing scale.

Two things are easy to break:

- **Stored names.** Event types (`EventTypes`) and game kinds (`GameKind`) are written to the database by name. Renaming one breaks existing journals unless a migration rewrites them.
- **New events and rules.** The fold must keep replaying old journals to the same state: change how an existing event is applied only with a migration in mind.

## Where things are written down

- `CONTEXT.md`: the domain glossary. Use its terms in code, tests and tickets.
- `docs/adr/`: decisions that are hard to reverse, and why they were made.
- `.scratch/<feature>/`: specs and tickets, as local markdown (`docs/agents/issue-tracker.md`).
- `docs/release/`: Play listing, data safety and release steps.
