# 0018. The git gates parse the command and judge each git invocation in the repo it targets

Date: 2026-10-16
Status: accepted

## Context
Every git gate found its subcommand with a regex that needed the subcommand right after `git` (`(^|[;&|()]+[[:space:]]*)git[[:space:]]+commit`). `git -C <repo> commit`, `git -c k=v commit`, `git --git-dir=… push --force` and `FOO=1 git commit` matched none of them, so the secret scan, commit hygiene, review gate, pre-commit checks and the push protections were all skipped, and even a detected commit was checked against the session's cwd rather than the repo it targets. Claude uses `git -C` routinely in worktrees, so this was the common path, not an edge case.

Regexes cannot fix both halves: they cannot tell which repo a `cd … &&` or `-C` selects, and loosening them makes quoted text and commit messages fire (`echo "git push --force"`, a heredoc commit body that names a command). The hooks may only use bash, jq and git, and must run on macOS's bash 3.2.

## Decision
A shared bash tokenizer (`scripts/_git-cmd.sh`) finds every git invocation in the command (quotes, operators, subshells, substitutions, heredocs, `bash -c`, `cd`, git's global options) and the gates judge each one against the repo it targets. Quoted text and heredoc bodies are data. Two exceptions keep the old safety net: the ask-only reset/clean/branch rules still also fire on their loose text match, and `pre-commit-checks` runs lint and tests only for a commit in the session's own repo.

## Consequences
- `git -C`, `-c`, `--git-dir`/`--work-tree`, `cd <repo> &&`, compound commands and `bash -c '…'` all get the same decision as the plain form, against the right repo (`tests/git-gates.test.sh`).
- False positives on quoted text are gone for every deny rule and every commit gate.
- Given up: a deny-level form the parser does not follow now passes where the old regex happened to catch it. Not followed: git or shell aliases and functions, `GIT_DIR=…` prefixes, variables other than `$HOME` in a path (the gate falls back to the session's repo), wrappers beyond env/command/builtin/exec/nohup/time (`sudo git push --force` passes, as it did before).
- A review recorded in session A never satisfies the gate for a commit in repo B: such a commit needs a session in B, or `RANGER_SKIP_REVIEW=1`.
- A commit in another repo gets no lint/tests from the hook (before, it got the session repo's tests, which was wrong anyway). Running them there would execute that repo's code before the user approves the command, which a prompt-injected `git -C <clone> commit` could use.
- The parser is ~350 lines of bash that has to be kept in step with the gates; the test suite and its mutation check are the guard. Per-token cost is O(length) in bash, so only commands of >100 KB of short words get slow; heredocs stay linear.
- Door: two-way; cost if wrong: revert the scripts to the regexes (one commit).

## Alternatives considered
- Patch the regexes to allow global options (`git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-][^[:space:]]*)?)*[[:space:]]+commit`) — finds more commits but still not the target repo, and `-C`'s value cannot be told from the subcommand without a parse.
- Fail safe everywhere (strip quotes, split on operators, fire on any match) — every commit message or file write that mentions `git push --force` would be denied.
- Parse with awk, python or a shell parser binary — not in the bash + jq + git budget, and python is missing on clean Windows machines.
