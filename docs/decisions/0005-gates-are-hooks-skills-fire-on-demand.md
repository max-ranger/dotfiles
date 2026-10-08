# 0005. Gates are hooks; review and verification are demanded, not suggested

Date: 2026-10-08
Status: accepted

## Context
Review, simplification and security skills never ran on their own in auto mode. `claude -p` from a hook needs a separate CLI login that cannot be guaranteed per session or in cloud sessions. Prompt/agent hook types cannot run git.

## Decision
Deterministic command hooks hold the line and the in-session model does the judging:
- **Review gate** (PreToolUse `git commit`): deny when source files are staged and no `/code-review` ran against the current HEAD. Docs-only commits pass. `RANGER_SKIP_REVIEW=1` is the emergency bypass.
- **Verify gate** (Stop): block when source code was edited this session and no test command ran after the last edit; two blocks per edit cycle, then it lets go. Only in repos with a test runner.
- **Design check** (PreToolUse Edit/Write): once per session, the first UI-file edit is denied with the instruction to decide whether `emil-design-eng` or `impeccable` should run first.
- Trackers (PostToolUse on Skill, Bash, Edit) write markers under `.git/ranger/`.

## Consequences
- Every code commit has been reviewed since the previous commit; every stop after code edits has a test run behind it.
- Cost: one review per commit, one test run per edit cycle, one redo of the first UI edit per session.
- Markers live in `.git/`, never committed, per worktree.

## Alternatives considered
- `claude -p` review in the hook — auth not guaranteed.
- Broader skill trigger descriptions — the model still decides "no" once work looks done.
