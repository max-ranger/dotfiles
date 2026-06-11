#!/bin/bash
# SessionStart: surface this repo's basic-memory project and nudge the
# knowledge-capture protocol (full rules in ~/.claude/CLAUDE.md).
# Thin by design: resolve repo -> project name, check existence in
# ~/.basic-memory/config.json, emit one additionalContext line.
# No-op outside a git repo.

source ~/.claude/hooks/_parse-input.sh   # consumes stdin; exposes _json_extract/_json_decode

CWD=$(_json_decode "$(_json_extract cwd)")
[ -z "$CWD" ] && CWD="$PWD"

REPO_ROOT=$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null)
[ -z "$REPO_ROOT" ] && exit 0

PROJECT=$(basename "$REPO_ROOT")
CONFIG="$HOME/.basic-memory/config.json"

if [ -f "$CONFIG" ] && jq -e --arg p "$PROJECT" '.projects[$p]' "$CONFIG" >/dev/null 2>&1; then
  MSG="📓 basic-memory project \`${PROJECT}\`: before substantive work, load context (recent_activity + Overview). Capture durable decisions at checkpoints — draft, confirm, then write."
else
  MSG="📓 No basic-memory project for \`${PROJECT}\` yet: offer to create one before capturing knowledge. Capture durable decisions at checkpoints — draft, confirm, then write."
fi

jq -nc --arg m "$MSG" \
  '{continue:true,suppressOutput:true,hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$m}}'
