#!/bin/bash
# SessionStart: surface this session's basic-memory project and nudge the
# knowledge-capture protocol (full rules in ~/.claude/CLAUDE.md).
# Thin by design: resolve cwd -> project (repo -> parent -> cwd, see
# _basic-memory-project.sh), emit one additionalContext line.
# basic-memory is LOCAL and FILE-FIRST: no MCP server, ever. Reads and writes go
# through the `basic-memory` / `bm` CLI or straight to the markdown files under
# the project path, followed by `bm reindex`.

source ~/.claude/hooks/_parse-input.sh   # consumes stdin; exposes _json_extract/_json_decode

CWD=$(_json_decode "$(_json_extract cwd)")
[ -z "$CWD" ] && CWD="$PWD"

source ~/.claude/hooks/_basic-memory-project.sh
bm_resolve_project "$CWD"

CONFIG="$HOME/.basic-memory/config.json"
VAULT=""
[ -n "$BM_PROJECT" ] && VAULT=$(jq -r --arg p "$BM_PROJECT" '.projects[$p].path' "$CONFIG" 2>/dev/null | tr -d '\r')

READ_HINT="Load context first: \`basic-memory tool recent-activity --project ${BM_PROJECT} --timeframe 7d\`, then read \`${VAULT}\\Overview.md\`"
WRITE_HINT="Capture: ticket notes (tickets/<ID> ...) are written DIRECTLY at checkpoints, no approval needed; hub (Overview) and decisions/ changes are drafted and confirmed first. After any direct file write run \`bm reindex --project \"${BM_NAME}\"\` (no watcher is running). Queue for hub/decision candidates only: ~/.claude/memory-queue/${BM_PROJECT}.md"

case "$BM_VIA" in
  parent)
    MSG="📓 basic-memory project \`${BM_PROJECT}\` (multi-repo; this repo is \`${BM_REPO}\`). ${READ_HINT}, \`${BM_REPO}\\Overview.md\` and the ticket note under \`${BM_REPO}\\tickets\\\` (or \`tickets\\\` at project level for cross-repo tickets). ${WRITE_HINT}"
    ;;
  repo)
    MSG="📓 basic-memory project \`${BM_PROJECT}\`. ${READ_HINT} and the ticket note under \`tickets\\\` if the work has a ticket. ${WRITE_HINT}"
    ;;
  cwd|cwd-parent)
    MSG="📓 basic-memory project \`${BM_PROJECT}\` (session opened at the workspace root, not inside a repo). ${READ_HINT}; per-repo hubs are \`<repo>\\Overview.md\`, cross-repo tickets under \`tickets\\\`. ${WRITE_HINT}"
    ;;
  *)
    NAME=$(basename "$CWD")
    MSG="📓 No basic-memory project for \`${NAME}\` or its parent folder. ASK the user whether one should be created (\`basic-memory project add <name> <path>\`) -- do not create it unprompted and do not capture knowledge into an unregistered folder. If they decline, drop the subject for the rest of the session."
    ;;
esac

jq -nc --arg m "$MSG" \
  '{continue:true,suppressOutput:true,hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$m}}'
