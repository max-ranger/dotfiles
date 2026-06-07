# CLAUDE.md — Global

> Living document. After every correction: update this file so the mistake doesn't repeat.

---

## Code Rules

**Naming**
- Variables, functions, types must be self-explanatory — no abbreviations except `id`, `url`, loop counters
- Booleans: `is*`, `has*`, `can*`, `should*` prefix

**Functions**
- One responsibility per function. If you need a comment to explain what a block does, extract it into a named function instead
- Max 3–4 parameters — use an options object when exceeded
- No boolean parameters that change behavior — split into two functions

**No duplication**
- Before writing logic, check if it exists
- Extract shared logic when it appears 2+ times

**Error handling**
- Never swallow errors silently (`catch (e) {}` is forbidden)
- Always handle the unhappy path explicitly
- Log errors with context, not just the message

**Constants**
- No magic numbers or strings — use named constants

**Early exit**
- Validate and return/throw at the top; avoid deep nesting

**Comments**
- Comments explain *why*, not *what* — the code explains what
- Public APIs and exported functions get a short doc comment

**Imports**
- Always use `@/` alias paths, never `../` relative paths
- The only exception: `./` relative imports within a single-component directory (e.g. `Button.vue` importing from its sibling `index.ts`)
- Import order is enforced by ESLint (`simple-import-sort`): node builtins → external packages → `@/` aliases → `./` relative
- Use `import type` for type-only imports (enforced by `@typescript-eslint/consistent-type-imports`)
- Public entry points (`index.ts`) must use `./` relative paths — `@/` aliases don't resolve in emitted `.d.ts` files

---

## Testing

- Write unit tests for business logic and non-trivial transformations
- Test behavior, not implementation — tests must survive refactors
- Mock all I/O, external APIs, and databases in unit tests
- Don't test framework code or trivial getters

---

## Git

- Use Semantic Commit Messages
- Never add `Co-Authored-By` lines to commits
- Never commit claude specific files
- Never commit claude plugin related files
- Never commit claude doc files or execution plans

---

## Verification Before Done

- Never claim a task is complete without running the verification commands and seeing them pass. Quote the pass count in your summary (e.g., "158/158 passing").
- After code edits, run the project's type-check/build AND test suite before reporting done. The `/verify` skill runs the right commands per stack.
- When adding a dependency that already exists in a sibling workspace or package, match its version exactly — do not scaffold with a fresh `^latest`.
- If verification fails: fix and re-run. No partial success.

---

## Background Execution

- Long-running commands (builds, full test suites, deploys, anything expected to take >30s): always pass `run_in_background: true` on the Bash tool and continue with other work. Do not block.
- Poll via the `Monitor` tool or `BashOutput` when you need the result. Do not re-run the same command in a sleep loop.
- Applies to subagents too: dispatch independent Agent tool calls in a single message so they run concurrently, rather than serially awaiting each one.

---

## What NOT to do

- Don't over-engineer or add abstraction speculatively (YAGNI)
- Don't leave commented-out code — delete it
- Don't leave silent TODOs — either fix it or add `// TODO(owner): reason`
- Don't write comments that explain *what* the code does — only *why*
- Don't create files/classes/abstractions for future use cases that don't exist yet
