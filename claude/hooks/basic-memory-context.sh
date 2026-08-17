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
PARENT=$(basename "$(dirname "$REPO_ROOT")")
CONFIG="$HOME/.basic-memory/config.json"

# basic-memory lowercases/slugifies project names on creation (spaces -> hyphens),
# so compare slugs, not raw basenames. Repos that live inside a shared parent folder
# (e.g. a "Global Data Store" monorepo-style directory) are tracked as ONE project
# under the parent's name, not per sub-repo -- so fall back to the parent dir too.
_slug() { echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-'; }
PROJECT_SLUG=$(_slug "$PROJECT")
PARENT_SLUG=$(_slug "$PARENT")

MATCH=""
if [ -f "$CONFIG" ]; then
  if jq -e --arg p "$PROJECT_SLUG" '.projects[$p]' "$CONFIG" >/dev/null 2>&1; then
    MATCH="$PROJECT_SLUG"
  elif jq -e --arg p "$PARENT_SLUG" '.projects[$p]' "$CONFIG" >/dev/null 2>&1; then
    MATCH="$PARENT_SLUG"
  fi
fi

if [ -n "$MATCH" ]; then
  MSG="📓 basic-memory project \`${MATCH}\`: before substantive work, load context (recent_activity + Overview). Capture durable decisions at checkpoints — draft, confirm, then write."
else
  MSG="📓 No basic-memory project for \`${PROJECT}\` yet: offer to create one before capturing knowledge. Capture durable decisions at checkpoints — draft, confirm, then write."
fi

jq -nc --arg m "$MSG" \
  '{continue:true,suppressOutput:true,hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$m}}'
