# Review policy

## Passes
1. Hook scripts: `shellcheck -S warning` clean; every PreToolUse decision is JSON on stdout with `exit 0` (an `exit 2` discards the JSON).
2. Each gate has a pass path and a deny/block path exercised with synthetic input in a temp git repo.
3. `claude plugin validate` passes for the plugin and the marketplace.
4. Brewfile and `winget/packages.json` change together.
5. README reflects the change.

## Blocking by default
- A hook that can block without printing a reason.
- A Stop hook without a bound (infinite block).
- Secrets or machine-local paths in tracked files.
