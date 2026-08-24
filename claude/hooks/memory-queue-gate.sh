#!/bin/bash
# Stop-hook gate: blocks session end while this project's memory queue has
# unflushed entries. Per CLAUDE.md "In-session capture", Claude appends
# mid-session decisions/corrections to the queue file and must flush them
# (draft basic-memory notes, confirm-first) or discard them before stopping.
# Queue path: ~/.claude/memory-queue/<git-root or cwd, : and / -> ->.md
# (':' matters on Windows, where the git root is C:/... and NTFS forbids ':' in names)

INPUT=$(cat)

# Re-entrant stop: we already blocked once and Claude continued — let it end
# now even if the queue is still non-empty (e.g. waiting on user approval).
STOP_ACTIVE=$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)
[ "$STOP_ACTIVE" = "true" ] && exit 0

CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
[ -z "$CWD" ] && exit 0

ROOT=$(cd "$CWD" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null)
[ -z "$ROOT" ] && ROOT="$CWD"

QUEUE="$HOME/.claude/memory-queue/$(printf '%s' "$ROOT" | tr ':/' '--').md"
[ -f "$QUEUE" ] || exit 0
grep -q '[^[:space:]]' "$QUEUE" || exit 0

COUNT=$(grep -c '^- ' "$QUEUE" 2>/dev/null)
jq -n --arg r "Memory queue has ${COUNT:-0} unflushed entries: ${QUEUE}. Before ending, present them as draft basic-memory notes for approval (confirm-first) or discard entries that turned out to be trivia — then truncate the queue file." \
  '{decision: "block", reason: $r}'
exit 0
