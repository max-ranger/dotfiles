#!/bin/bash
# PreToolUse (Write|Edit|MultiEdit): guard writes into the basic-memory vault.
#
# basic-memory is used file-first (no MCP server), so "writing a note" is just a
# Write/Edit under the vault root. A note written into a folder that is NOT a
# registered project is invisible to basic-memory -- never indexed, never
# searchable, never surfaced by recent_activity. That is silent data loss.
#
# So: if the target sits under the vault root but its top-level folder is not a
# registered project, hand the decision to the user (permissionDecision "ask")
# instead of letting the write through unnoticed.
#
# Writes inside a registered project, and writes outside the vault entirely,
# pass straight through.

INPUT=$(cat)

TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
case "$TOOL" in
  Write|Edit|MultiEdit|NotebookEdit) ;;
  *) exit 0 ;;
esac

FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$FILE" ] && exit 0

CONFIG="$HOME/.basic-memory/config.json"
[ -f "$CONFIG" ] || exit 0

# Compare case-insensitively on forward slashes (Windows paths arrive either way).
# Length is preserved by both transforms, so offsets computed on the lowercased
# form stay valid for the display form.
# jq is a Windows build here and emits CRLF, so every value it hands back carries a
# trailing \r. Strip it first or nothing ever compares equal.
_slashes() { printf '%s' "$1" | tr -d '\r' | tr '\\' '/' | sed 's#/*$##'; }
_fold()    { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

FILE_DISP=$(_slashes "$FILE")
FILE_CMP=$(_fold "$FILE_DISP")

# ROOT = shortest registered project path containing the file (the vault root).
# BEST = longest such path. BEST != ROOT means the file is inside a real project.
ROOT=""
BEST=""
while IFS= read -r p; do
  [ -z "$p" ] && continue
  n=$(_fold "$(_slashes "$p")")
  case "$FILE_CMP/" in
    "$n"/*)
      if [ -z "$ROOT" ] || [ "${#n}" -lt "${#ROOT}" ]; then ROOT="$n"; fi
      if [ "${#n}" -gt "${#BEST}" ]; then BEST="$n"; fi
      ;;
  esac
done <<EOF
$(jq -r '.projects[]?.path // empty' "$CONFIG" 2>/dev/null | tr -d '\r')
EOF

[ -z "$ROOT" ] && exit 0            # not in the vault at all
[ "$BEST" != "$ROOT" ] && exit 0    # inside a registered project -> fine

REL="${FILE_DISP:$(( ${#ROOT} + 1 ))}"
case "$REL" in
  */*) TOP="${REL%%/*}" ;;
  *)   exit 0 ;;                    # loose file at the vault root -> belongs to the root project
esac

jq -nc --arg t "$TOP" --arg r "${FILE_DISP:0:${#ROOT}}" '
{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "ask",
    permissionDecisionReason: (
      "basic-memory: `" + $t + "` under " + $r + " is not a registered project " +
      "(~/.basic-memory/config.json). A note written there is never indexed or searchable. " +
      "Ask whether the project should be created first — `basic-memory project add \"" + $t +
      "\" \"" + $r + "/" + $t + "\"` — or approve to write the file anyway."
    )
  }
}'
exit 0
