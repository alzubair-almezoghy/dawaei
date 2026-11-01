# Dawaei · دوائي

Offline-first Android medication organizer, built incrementally in Flutter.

Start with [the Arabic setup guide](README.ar.md). The architecture, database and
scheduling decisions are in [docs/ARCHITECTURE.ar.md](docs/ARCHITECTURE.ar.md).

This build completes **Phases 1–5**: application foundation, SQLite medication
management, Arabic and English UI, bounded local reminders, and dose history with
explicit taken/skipped confirmation and adherence summaries.

```sh
flutter pub get
flutter gen-l10n
dart analyze
flutter test --concurrency=1
flutter run
```

See [validation results](docs/VALIDATION.ar.md) for checks actually executed and
[release requirements](docs/RELEASE.ar.md) before preparing a Google Play release.
