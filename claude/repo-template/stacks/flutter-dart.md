## Flutter / Dart

- Lints: `very_good_analysis` (or equally strict); `dart format` is enforced. Pick
  package-style or relative-style for internal `lib/` imports once per repo — never mix.
- No `!` unless the invariant is locally provable; `dynamic` only at JSON/platform
  boundaries, converted to typed models immediately.
- Extract widget **classes**, not `Widget _buildX()` helper methods (rebuild granularity,
  const-ability). `build` stays pure — no side effects, no business logic, no async.
- Business logic lives in providers/notifiers (Riverpod et al.); widgets only read state
  and dispatch intents.
- Data classes are immutable (`freezed` / `@immutable`); `const` constructors and widgets
  wherever the lint allows.
- User-facing strings only via l10n/ARB from the first commit — no hardcoded UI text.
- Never hand-edit generated files (`*.g.dart`, `*.freezed.dart`) — re-run `build_runner`.
- Widget tests target user-visible semantics (finders on text/labels, not internals);
  golden tests only for layout-critical custom widgets.
