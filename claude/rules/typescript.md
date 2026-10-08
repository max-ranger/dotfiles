---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.mjs"
---
# TypeScript / JavaScript

- Imports: `@/` aliases, never `../`. Exceptions: `./` inside a single-component directory, and public entry points (`index.ts`) which must use `./` (aliases don't resolve in emitted `.d.ts`).
- Import order and type-only imports are ESLint-enforced (`simple-import-sort`, `consistent-type-imports`) — don't fight the lints.
- Match the version of a dependency that already exists in a sibling package exactly; never scaffold a fresh `^latest`.
