---
paths:
  - "**/*.dart"
  - "**/pubspec.yaml"
---
# Flutter / Dart

- Lints: `very_good_analysis` (or equally strict); `dart format` enforced. One import style (package or relative) per repo, never mixed.
- No `!` unless locally provable; `dynamic` only at JSON/platform boundaries, converted to typed models immediately.
- Extract widget **classes**, not `Widget _buildX()` helpers. `build` stays pure: no side effects, no business logic, no async.
- Business logic in providers/notifiers (Riverpod et al.); widgets read state and dispatch intents.
- Data classes immutable (`freezed` / `@immutable`); `const` wherever the lint allows.
- User-facing strings via l10n/ARB from the first commit.
- Never hand-edit `*.g.dart` / `*.freezed.dart` — re-run `build_runner`.
- Widget tests target user-visible semantics; golden tests only for layout-critical custom widgets.
- Playwright cannot drive Flutter (canvas rendering); e2e = `integration_test` or Patrol.
