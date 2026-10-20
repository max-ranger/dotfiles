# 0019. Gates ignore bypasses and evidence the agent can forge

Date: 2026-10-20
Status: accepted

## Context
A review of affaan-m/ECC turned up two ways Claude could satisfy its own gates without doing the work.

The review gate skipped itself when the command text contained `RANGER_SKIP_REVIEW=1`. Claude writes that text, so Claude could wave its own commits through.

The verify gate accepted any recorded test run after the last edit. `track-tests` only sees commands that exited 0, because Claude Code sends a failed command to `PostToolUseFailure`. That held up for a plain `npm test`, but not for the forms Claude uses most. `flutter test 2>&1 | tail -1`, `npm test; echo done` and `npm test || true` exit 0 when the tests fail. A regex that matched the runner name anywhere also counted `grep -oE '(vitest|jest)' …` as a test run. The `exit` field `track-tests` stored was always empty, since PostToolUse carries no exit code.

## Decision
A bypass, or a piece of evidence, counts only if the agent can't produce it on its own.

- The review bypass is read only from the hook's environment, which it inherits from the Claude Code process. Max sets it by launching `RANGER_SKIP_REVIEW=1 claude`. Text in a command does nothing, and neither does the variable in the `env` of a user or project settings file, which the agent can edit.
- A Bash command counts as a test run only when a runner runs as a command (quoted text is data, `$( )` and `<( )` are not command positions) and its failure would have failed the whole command. After each runner, only `&&` may follow, or pipes when `set -o pipefail` comes first. Common launchers count (`npx`, `bunx`, `pnpm exec`, `fvm`, `python -m`, `uv run`).

## Consequences
- `npm test | tail`, `; echo`, `|| true` and `&` no longer satisfy the verify gate. Its message now says how to run tests so the run counts. Claude may spend one of its two blocks learning that.
- `tests/verify-gate.test.sh` covers both directions. The review bypass cases live in `tests/git-gates.test.sh`.
- Given up: a runner behind a wrapper the pattern doesn't know (`bash -c 'npm test'`, `if npm test; then`) doesn't count. The gate lets go after two blocks, so this costs a block, not a hang.
- Known gaps left open: `(set -o pipefail); npm test | tail` counts though pipefail is gone. Timestamps have one-second resolution, so a parallel test run can count for an edit it didn't see. A run in another repo (`cd ../other && npm test`) counts for the session's repo.
- An emergency commit needs a relaunch with the variable set. The agent can't do that, by design.
- Door: two-way. Reverting the two scripts restores the old behaviour.

## Alternatives considered
- Parse the exit code from PostToolUse: there is none. PostToolUseFailure only sees failures, so it can't tell a masked pass from a real one.
- Count piped runs by scanning the output for "failed": every runner prints failure differently. A run without output would pass, and a test named "failed" would block.
- Reuse the `_git-cmd.sh` tokenizer for runners: that's exact, but it couples the git parser to test detection for a gain over quote stripping that the tests don't show.
