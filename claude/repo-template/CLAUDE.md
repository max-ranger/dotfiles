# CLAUDE.md

> Universal base for any software project — merge with project-specific instructions below.
> Living document: after every correction, update this file so the mistake doesn't repeat.
> Biases toward caution over speed. For trivial tasks, use judgment.

---

## Working Principles

### 1. Think Before Coding
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't silently pick one.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop, name what's confusing, and ask — before implementing.

### 2. Simplicity First
- Minimum code that solves the problem. Nothing speculative.
- No features, abstractions, "flexibility", or configurability beyond what was asked.
- No error handling for impossible scenarios.
- No files, classes, or abstractions for future use cases that don't exist yet (YAGNI).
- If you write 200 lines and it could be 50, rewrite it. Ask: "Would a senior engineer call this overcomplicated?"

### 3. Surgical Changes
- Touch only what the request requires — every changed line should trace to it.
- Don't "improve", refactor, or reformat adjacent code that isn't broken.
- Match existing style, even if you'd do it differently.
- Remove orphans *your* change created (now-unused imports/vars/functions). Don't delete pre-existing dead code — mention it instead.

### 4. Goal-Driven Execution
- Turn tasks into verifiable goals: "Add validation" → "write tests for invalid inputs, then make them pass"; "Fix the bug" → "write a failing test that reproduces it, then make it pass".
- For multi-step work, state a brief plan with a verify check per step, then loop until each passes.

---

## Code Rules

**Naming** — Self-explanatory variables, functions, and types; no abbreviations except `id`, `url`, loop counters. Booleans use `is*`/`has*`/`can*`/`should*`.

**Functions** — One responsibility each. If a block needs a comment to explain what it does, extract it into a named function. Max 3–4 parameters (use an options object beyond that). No boolean parameters that switch behavior — split into two functions.

**No duplication** — Check whether the logic already exists before writing it. Extract shared logic once it appears 2+ times.

**Error handling** — Never swallow errors silently (`catch (e) {}` is forbidden). Handle the unhappy path explicitly. Log errors with context, not just the message.

**Constants** — No magic numbers or strings; use named constants.

**Early exit** — Validate and return/throw at the top; avoid deep nesting.

**Comments** — Explain *why*, not *what* — the code explains what. Public/exported APIs get a short doc comment. Delete commented-out code. No silent TODOs — either fix it or write `// TODO(owner): reason`.

---

## TypeScript / JavaScript (if applicable)

- Use `@/` alias paths, never `../` relative paths. Only exception: `./` relative imports within a single-component directory (e.g. `Button.vue` importing its sibling `index.ts`).
- Public entry points (`index.ts`) must use `./` relative paths — `@/` aliases don't resolve in emitted `.d.ts` files.
- Import order is enforced by ESLint (`simple-import-sort`): node builtins → external packages → `@/` aliases → `./` relative.
- Use `import type` for type-only imports (`@typescript-eslint/consistent-type-imports`).

---

## Vue (if applicable)

- Composition API with `<script setup lang="ts">` only — no Options API in new code.
- Props via `defineProps<T>()` (+ `withDefaults`), events via `defineEmits<T>()` — both fully typed; no untyped `$emit` strings.
- Multi-word PascalCase component names/filenames (`CourseCard.vue`, never `Card.vue`).
- `v-for` always with `:key`; never `v-if` and `v-for` on the same element.
- Shared stateful logic goes into composables (`useX`); components stay thin and presentational.
- State: Pinia for cross-cutting/global state; props down + emits up for parent-child — don't reach for the store when a prop does the job.
- Styles `scoped` (or CSS modules); no global style leaks from components.
- Template expressions stay trivial — anything with logic becomes a `computed`.

---

## C# / .NET (if applicable)

- Nullable reference types enabled; warnings are errors. No `!` (null-forgiving) unless the invariant is locally provable.
- Naming: PascalCase public members, `_camelCase` private fields, `Async` suffix on async methods, `I` prefix on interfaces.
- `async`/`await` all the way down — never `.Result` / `.Wait()` (deadlocks). `ConfigureAwait(false)` in library code.
- Immutable data as `record` types / `init` setters; mutate only where mutation is the point.
- Dependency injection via constructor; no service-locator pattern, no `new`-ing services inside classes.
- Exceptions are for exceptional cases — no exception-driven control flow; validate and return early instead.
- LINQ when it's clearer than a loop; watch for multiple enumeration of `IEnumerable`.
- `.editorconfig` + `dotnet format` are the formatting truth; don't fight them.

---

## Flutter / Dart (if applicable)

- Lints: `very_good_analysis` (or an equally strict set); `dart format` is enforced — CI fails on unformatted code.
- Imports ordered `dart:` → `package:` → relative (`directives_ordering`). Pick package-style or relative-style for internal `lib/` imports once per repo and never mix.
- Null safety: no `!` unless the invariant is locally provable — prefer `??`, pattern matching, or early exit. `dynamic` only at JSON/platform boundaries, converted to typed models immediately.
- Data classes are immutable (`freezed` / `@immutable`); use `const` constructors and `const` widgets wherever the lint allows.
- Extract widget **classes**, not `Widget _buildX()` helper methods (rebuild granularity, const-ability). `build` stays pure — no side effects, no business logic, no async.
- Business logic lives in providers/notifiers (Riverpod et al.); widgets only read state and dispatch intents.
- Async: no unawaited futures (`unawaited_futures`); never use a `BuildContext` after an `await` without a `mounted` check (`use_build_context_synchronously`).
- User-facing strings only via l10n/ARB — no hardcoded UI text, from the first commit.
- Never hand-edit generated files (`*.g.dart`, `*.freezed.dart`); re-run `build_runner` after model changes.
- Screens get widget tests against user-visible semantics (finders on text/labels, not implementation internals); golden tests only for layout-critical custom widgets.

---

## Testing

- Write unit tests for business logic and non-trivial transformations.
- Test behavior, not implementation — tests must survive refactors.
- Mock all I/O, external APIs, and databases in unit tests.
- Don't test framework code or trivial getters.

---

## Verification Before Done

- Never claim a task is complete without running the verification commands and seeing them pass. Quote the pass count in your summary (e.g. "158/158 passing").
- After code edits, run the project's type-check/build **and** test suite before reporting done — use the project's own scripts (`package.json`, `Makefile`, `Taskfile`, `dotnet test`, `cargo test`, `pytest`, `flutter analyze && flutter test`, etc.).
- When adding a dependency that already exists in a sibling workspace or package, match its version exactly — don't scaffold with a fresh `^latest`.
- If verification fails: fix and re-run. No partial success.

---

## Git

- Use semantic commit messages.
- Never add `Co-Authored-By` lines to commits.
- Never commit Claude-specific files, plugin files, doc files, or execution plans.

---

## Background Execution (Claude Code)

- Long-running commands (builds, full test suites, deploys — anything expected to take >30s): pass `run_in_background: true` on the Bash tool and continue with other work. Don't block.
- Poll via the `Monitor` tool or `BashOutput` when you need the result. Don't re-run the same command in a sleep loop.
- Applies to subagents too: dispatch independent `Agent` calls in a single message so they run concurrently rather than serially.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come *before* implementation rather than after mistakes.
