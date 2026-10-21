# 0020. The verify gate counts a test run by when it started and where it ran

Date: 2026-10-21
Status: accepted (closes the known gaps listed in 0019)

## Context
Decision 0019 left three ways a test run could satisfy the verify gate without testing the edited code:

- `(set -o pipefail); npm test | tail` counted, although pipefail ended with the subshell.
- Markers had one-second timestamps taken when the run finished. A test run sent in parallel with an edit could run against the old code and still finish after it.
- Every run was recorded for the session's repo. `cd ../other && npm test` satisfied the gate for an edit in this repo.

## Decision
- A `( … )` group that closes before the runner no longer counts. A `set -o pipefail` or a `cd` inside it is ignored.
- A second hook, `track-tests.sh start` on PreToolUse, notes when each possible test command starts, keyed by the tool call's id. The PostToolUse record carries that start time. Marker timestamps are sub-second (jq's clock). A run counts only if it started after the edit landed.
- `track-edits` records the edited file's repo. `track-tests` files each run under the repo it ran in, following `cd`/`pushd` (relative, absolute, `~`). The gate looks up the run for the edited file's repo. A `cd` to a variable names no real folder, so nothing is recorded.

## Consequences
- `tests/verify-gate.test.sh` covers each case, and each new branch survives no mutation.
- An edit outside any repo (a scratch file) no longer arms the gate.
- A start note whose run a gate denied never gets its PostToolUse. Notes older than a day are deleted.
- Still not followed: `npm --prefix`, `pnpm -C`, `dotnet test <path>` into another repo. A run there counts for the cwd's repo. Only the last edit is checked, as before.
- Door: two-way. Reverting the four scripts restores 0019's behaviour.

## Alternatives considered
- Higher-resolution finish times alone: a parallel run still finishes after the edit, so ordering by finish time can't tell it tested old code.
- One marker per session listing every repo: a map in one JSON file needs read-modify-write from parallel hooks. A file per repo doesn't.
