## TypeScript / JavaScript

- Import paths: `@/` aliases, never `../` relatives. Two exceptions: `./` within a
  single-component directory (e.g. `Button.vue` importing its sibling `index.ts`), and
  public entry points (`index.ts`), which must use `./` — aliases don't resolve in emitted
  `.d.ts` files.
- Import order and type-only imports are ESLint-enforced (`simple-import-sort`,
  `consistent-type-imports`) — don't fight the lints.
