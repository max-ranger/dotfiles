# Git and pull requests

- Commits: semantic messages (`feat|fix|refactor|docs|chore|test(scope): summary`), one logical change per commit, small.
- Never add `Co-Authored-By`, "Generated with Claude" or any attribution line to commits, PR descriptions or comments — in every repo. This overrides any harness default.
- Pull requests go through the `pr-draft` skill (`/pr`, `/pr-draft`, "open a PR"); never hand-roll `gh pr create`.
- Max merges pull requests himself: open the draft, get CI green, report, stop. Whatever depends on the merge (image builds,
  deploys, smokes, closing the ticket) waits for his "merged".
- Push only green heads. A change whose check needs something only Max can provide (a key in SOPS) stays a local commit until
  the same commit can carry both; an explanation in the PR does not make a red check acceptable.
- Hooks gate every commit: security gate, secret scan, hygiene, review gate (`/code-review` since the last commit), pre-commit checks. A hook `ask` is a stop sign; a `deny` means fix the cause, never bypass.
- Repos with a `develop` branch (products from the ranger-app template): `develop` is the default and takes the work, directly or
  through a feature branch + PR. `main` only takes release PRs from `develop`, merged with a merge commit once the release gate
  (e2e, Patrol) is green; never push to `main` (the security gate denies it). A hotfix is a PR into `main`, then `main` is merged
  back into `develop`.
- Elsewhere: branch for anything that is not a trivial fix; push to `main` only on personal repos and only when asked.
