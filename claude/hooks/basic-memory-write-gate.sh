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
#
# Two vault layouts exist across machines and both must work:
#   nested   -- the vault root is itself a registered project (e.g. `main`) and the
#               other projects live in sub-folders of it;
#   siblings -- nothing is registered at the vault root, every project is a sibling
#               folder under a plain directory (e.g. ~/BasicMemory/<project>).
# A "vault root" is therefore a directory that is the parent of >= 2 registered
# projects, or a registered project that is the parent of another one.

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
# jq is a Windows build on one machine and emits CRLF, so every value it hands
# back carries a trailing \r. Strip it first or nothing ever compares equal.
_slashes() { printf '%s' "$1" | tr -d '\r' | tr '\\' '/' | sed 's#/*$##'; }
_fold()    { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
_under()   { case "$1/" in "$2"/*) return 0 ;; esac; return 1; }   # $1 is at/below dir $2

FILE_DISP=$(_slashes "$FILE")
FILE_CMP=$(_fold "$FILE_DISP")

# Registered project paths, normalized.
PROJECTS=()
while IFS= read -r p; do
  [ -z "$p" ] && continue
  PROJECTS+=("$(_fold "$(_slashes "$p")")")
done <<EOT
$(jq -r '.projects[]?.path // empty' "$CONFIG" 2>/dev/null | tr -d '\r')
EOT
[ "${#PROJECTS[@]}" -gt 0 ] || exit 0

# Vault roots (see header): parent of >= 2 projects, or a project that is the
# parent of another. dirname(<root project>) is deliberately NOT a vault root --
# otherwise every write under C:/ or $HOME would be gated.
VAULTS=()
_is_vault() { local v; for v in "${VAULTS[@]}"; do [ "$v" = "$1" ] && return 0; done; return 1; }
for p in "${PROJECTS[@]}"; do
  d=$(dirname "$p")
  n=0
  for q in "${PROJECTS[@]}"; do
    [ "$(dirname "$q")" = "$d" ] && n=$((n + 1))
    [ "$q" = "$d" ] && n=$((n + 2))
  done
  [ "$n" -ge 2 ] && ! _is_vault "$d" && VAULTS+=("$d")
done

# Deepest (BEST) and shallowest (ROOT) registered project containing the file.
ROOT=""; BEST=""
for p in "${PROJECTS[@]}"; do
  _under "$FILE_CMP" "$p" || continue
  if [ -z "$ROOT" ] || [ "${#p}" -lt "${#ROOT}" ]; then ROOT="$p"; fi
  if [ "${#p}" -gt "${#BEST}" ]; then BEST="$p"; fi
done

if [ -n "$BEST" ]; then
  [ "$BEST" != "$ROOT" ] && exit 0      # nested inside a real project
  _is_vault "$BEST" || exit 0           # leaf project -> fine
  V="$BEST"                             # root project: gate its sub-folders
else
  V=""                                  # no project owns it: inside a vault root?
  for v in "${VAULTS[@]}"; do
    _under "$FILE_CMP" "$v" || continue
    if [ -z "$V" ] || [ "${#v}" -gt "${#V}" ]; then V="$v"; fi
  done
  [ -z "$V" ] && exit 0                 # not in the vault at all
fi

REL="${FILE_DISP:$(( ${#V} + 1 ))}"
case "$REL" in
  */*) TOP="${REL%%/*}" ;;
  *)   [ -n "$BEST" ] && exit 0         # loose file inside the root project -> fine
       TOP="$REL" ;;                    # loose file at a siblings-layout root: nobody indexes it
esac

jq -nc --arg t "$TOP" --arg r "${FILE_DISP:0:${#V}}" '
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
