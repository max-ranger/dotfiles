#!/bin/bash
# Stop-hook gate: blocks session end while this project's memory queue has
# unflushed entries. Per CLAUDE.md "Knowledge Memory", the queue only holds
# candidates for hub/decision notes (ticket notes are written directly); before
# stopping, Claude must flush them into basic-memory (confirm-first), discard the
# ones that turned out to be trivia, or -- on the USER's explicit say-so only --
# leave a `- DEFER: <reason>` line, which is the single escape hatch.
#
# Queue path: ~/.claude/memory-queue/<basic-memory project slug>.md, resolved the
# same way the SessionStart hook resolves the project (repo -> parent -> cwd), so
# a session opened in gds-backend and one opened at the workspace root share one
# queue. No registered project -> nothing to gate.
#
# Deliberately NO `stop_hook_active` bypass: the previous version let the session
# end on the second stop attempt, which turned the gate into a one-shot nudge and
# let three sessions' worth of entries pile up (2026-09-02..04).

INPUT=$(cat)

CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null | tr -d '\r')
[ -z "$CWD" ] && exit 0

source ~/.claude/hooks/_basic-memory-project.sh
bm_resolve_project "$CWD"
[ -n "$BM_PROJECT" ] || exit 0

QUEUE="$BM_QUEUE"
[ -f "$QUEUE" ] || exit 0
grep -q '[^[:space:]]' "$QUEUE" || exit 0

# Explicit deferral by the user: let the session end, the entries stay queued.
if grep -qE '^- DEFER:' "$QUEUE"; then
  exit 0
fi

COUNT=$(grep -c '^- ' "$QUEUE" 2>/dev/null)
jq -n --arg r "Memory queue for basic-memory project '${BM_PROJECT}' has ${COUNT:-0} unflushed entries: ${QUEUE}. Before ending: (1) write the ticket note(s) directly (timeline, status, handoff) if not already done; (2) present hub/decision changes as drafts and get approval, then write them; (3) run: bm reindex --project \"${BM_NAME}\"; (4) truncate the queue file. Discard entries that are trivia. Only if the USER explicitly says to defer, append a line '- DEFER: <reason>' and stop." \
  '{decision: "block", reason: $r}'
exit 0
