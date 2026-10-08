#!/bin/bash
# PostToolUse (Edit|Write|MultiEdit): remember the last source-code edit of this session,
# so the verify gate can demand a test run that happened AFTER it.
INPUT=$(cat)
source "$(dirname "$0")/_markers.sh"
mk_init "$INPUT"
[ -n "$MK_DIR" ] || exit 0
FILE=$(printf '%s' "$INPUT" | _j '.tool_input.file_path // empty')
[ -z "$FILE" ] && exit 0
mk_is_code "$FILE" || exit 0
SAFE=$(printf '%s' "$FILE" | jq -Rsr @json)
mk_write last-edit "{\"file\":$SAFE}"
exit 0
