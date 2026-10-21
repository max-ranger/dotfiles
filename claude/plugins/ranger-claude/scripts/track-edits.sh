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
# the repo the edited file lives in: the verify gate wants a test run in that repo.
# An edit outside any repo (a scratch file) isn't code under test.
REPO=$(git -C "$(dirname "$FILE")" rev-parse --show-toplevel 2>/dev/null) || exit 0
mk_write last-edit "$(jq -nc --arg f "$FILE" --arg r "$REPO" '{file:$f,repo:$r}')"
exit 0
