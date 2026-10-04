# AGENTS.md — 羽记 FeatherNote

Cross-platform, offline-first Markdown notes & todo app built with Flutter (Riverpod + Drift/SQLite + go_router). Targets Android, iOS, macOS, Windows, Linux, and web. No backend — all data is local.

## Commands

```sh
flutter pub get                                        # install deps
flutter analyze                                        # lint/typecheck (flutter_lints)
flutter test                                           # all tests
flutter test test/unit/controllers/todo_controller_test.dart   # single file
dart run build_runner build --delete-conflicting-outputs       # regenerate Drift *.g.dart
flutter run -d macos                                   # run (also -d windows / -d chrome ...)
```

## Architecture

Feature-first layout under `lib/`:

- `lib/core/` — shared infrastructure: `database/` (Drift `AppDatabase` + `tables/`), `providers/`, `router/app_router.dart` (all go_router routes live here), `theme/`, `utils/`, `widgets/` (reusable widgets prefixed `Feather`, e.g. `FeatherSearchBar`).
- `lib/features/<feature>/` — features: `notes`, `tags`, `todos`, `settings`, `archive_trash`. Each is split into `domain/` (models + abstract repository interfaces), `data/` (Drift or SharedPreferences implementations), `presentation/` (screens, controllers, widgets).

Layer rules:
- UI/controllers depend on domain abstractions (`NoteRepository`, `TagRepository`, `SettingsRepository`), not on Drift directly. Repositories are wired via providers in `core/providers/database_provider.dart`.
- Features may import other features' controllers/providers (e.g. todos reads notes' `activeNotesStreamProvider`); keep such coupling one-directional and minimal.
- Riverpod patterns: `StreamProvider` for reactive lists, `select()` to scope rebuilds (see `app.dart`), plain `Provider<XxxController>` classes taking `Ref` for command-style mutations.

## Data-layer gotchas (Drift)

- Schema version lives in `lib/core/database/app_database.dart` (currently 2). Any table change: bump `schemaVersion`, add migration logic, and re-run build_runner. Tests use `AppDatabase.forTesting(NativeDatabase.memory())`.
- `notes_fts` is an FTS5 trigram virtual table (enables Chinese substring search) with self-healing create/backfill in `MigrationStrategy.beforeOpen`. If FTS5 is unavailable, search silently degrades to LIKE; queries < 3 chars always use LIKE. Don't remove the triggers — they deliberately delete-then-insert because `INSERT OR REPLACE` does not fire AFTER DELETE triggers.
- Tags are stored as one comma-separated string in `notes.tags`. When filtering by tag, use the delimited-LIKE pattern (`',' + tags + ',' LIKE '%,tag,%'`) — a plain substring match would match 「工作」 inside 「工作任务」.
- Deletion is soft (`isDeleted`/`deletedAt`); archive is `isArchived`. Every query for "live" notes must filter `isDeleted == false`.
- Every mutation must bump `updatedAt` manually via `copyWith`.

## Todos feature

There is no todos table. Todos are parsed out of note Markdown content (`- [ ]` / `- [x]`, regex in `core/utils/text_utils.dart`). Checking, adding, or deleting a todo rewrites the owning note's content. A parse cache keyed by note id avoids re-scanning on every stream emission — invalidate it if you change content-mutation paths.

## Offline-first constraints

- `GoogleFonts.config.allowRuntimeFetching = false` in `lib/bootstrap.dart`; Plus Jakarta Sans is bundled in `assets/google_fonts/`. Never add runtime network fetches for fonts or assets.
- Web builds require `sqlite3.wasm` and `drift_worker.js`; DB opens lazily on first query, and sample notes are seeded after the first frame if the DB is empty (`_seedInitialNotesIfEmpty` in `bootstrap.dart`).

## Conventions

- Comments, doc comments (`///`), and user-facing strings are written in Chinese. Follow suit.
- `lib/` code uses relative imports; tests use `package:feathernote/...` imports.
- Note card colors are referenced by string `colorId` (`default`, `sakura`, `sage`, `lavender`, `amber`, `sky`) mapped in `core/theme/`.
- `*.g.dart` files are generated and excluded from analysis — never hand-edit them.
