# Review policy

What `/code-review`, the verifier agent and a human reviewer check on every change in this repo.
Findings are **Blocking** (must fix before merge) or **Nit** (optional).

## Passes

1. **Correctness against the spec** — every requirement in `docs/specs/<feature>/spec.md` is met; departures from `plan.md` are reflected in the plan.
2. **Bugs** — edge cases, error paths, concurrency, resource handling.
3. **Security** — untrusted input validated at the trust boundary, authz on every entry point, no secrets, no injection.
4. **Simplicity** — the simplicity ladder was climbed; no speculative abstraction, no drive-by refactor, no new dependency for one call.
5. **Tests** — new behavior has tests that fail without the change; existing tests pass.
6. **Docs** — `docs/` and the ADRs reflect the change when it alters architecture or a decision.

## Exclusions

- Formatting (the formatter owns it), import order (lint owns it).
- <project-specific exclusions>

## Blocking by default

- Data loss or migration without rollback path
- Auth / permission changes without a test
- <project-specific>
