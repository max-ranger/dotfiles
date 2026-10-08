# Git and pull requests

- Commits: semantic messages (`feat|fix|refactor|docs|chore|test(scope): summary`), one logical change per commit, small.
- Never add `Co-Authored-By`, "Generated with Claude" or any attribution line to commits, PR descriptions or comments — in every repo. This overrides any harness default.
- Pull requests go through the `pr-draft` skill (`/pr`, `/pr-draft`, "open a PR"); never hand-roll `gh pr create`.
- Hooks gate every commit: security gate, secret scan, hygiene, review gate (`/code-review` since the last commit), pre-commit checks. A hook `ask` is a stop sign; a `deny` means fix the cause, never bypass.
- Branch for anything that is not a trivial fix; push to `main` only on personal repos and only when asked.
