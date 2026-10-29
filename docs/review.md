# Review policy

## Passes
1. Brewfile and `winget/packages.json` change together.
2. Scripts: `shellcheck -S warning` clean for bash, dry run by default for anything that moves files.
3. README reflects the change.

## Blocking by default
- Secrets or machine-local paths in tracked files.
- A script that applies changes without a dry-run flag.
