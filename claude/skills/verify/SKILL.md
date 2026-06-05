---
name: verify
description: Use when asked to verify, or before claiming any task is done, fixed, or complete — runs this project's type-check/build and test suite and reports pass counts with evidence.
---

# Verify

Run the current project's verification suite and report pass/fail counts. Never claim "done" without evidence from an actual command run.

## What to run

Detect the stack from files at the project root, then run the matching sequence. Stop on first failure.

### Vue / TypeScript monorepo
Triggers: `pnpm-workspace.yaml` exists, or `package.json` has `vue-tsc` in deps.

1. `pnpm vue-tsc --noEmit` (or `pnpm -r --filter './packages/**' exec vue-tsc --noEmit` for workspace)
2. `pnpm test` (or `pnpm -r test`)
3. `pnpm lint` — only if a `lint` script exists

### Plain Node / TypeScript
Triggers: `tsconfig.json` exists, no `vue-tsc`.

1. `pnpm tsc --noEmit` or `npx tsc --noEmit`
2. `pnpm test` or `npm test`

### .NET
Triggers: `.sln` or `*.csproj` at root.

1. `dotnet build --nologo -clp:ErrorsOnly`
2. `dotnet test --nologo`

### Full-stack
If both Node and .NET markers are present, run the frontend sequence first, then the backend sequence. Both must be green.

## Report format

After every command, output one line with the exit code and a concrete count. Example:

```
vue-tsc --noEmit              → 0 errors
pnpm test                     → 158/158 passing (5 suites)
dotnet test                   → 42/42 passing
```

On failure: stop, print the last 30 lines of output, and do **not** claim the task is complete until the pipeline is green.

## Rules

- Never skip steps because "the change is too small to matter". Type errors and regressions surface anywhere.
- Never report "should pass" or "likely passing" — quote the actual command output.
- If the project has no tests, say so explicitly. Don't count the absence of tests as success.
- When adding a dependency that already exists in a sibling workspace/package, match its version exactly. Don't introduce drift with a fresh `^latest`.
- If the verification commands differ from this skill's defaults (custom scripts, Makefiles, Taskfiles), run the project's actual scripts instead — but still report pass counts the same way.
