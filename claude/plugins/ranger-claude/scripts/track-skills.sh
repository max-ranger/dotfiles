#!/bin/bash
# PostToolUse (Skill): record that a review or design skill ran, so the review gate
# (git commit) and the design pre-trigger (UI edits) can check for it deterministically.
INPUT=$(cat)
source "$(dirname "$0")/_markers.sh"
mk_init "$INPUT"
[ -n "$MK_DIR" ] || exit 0

SKILL=$(printf '%s' "$INPUT" | _j '.tool_input.skill_name // .tool_input.skill // .tool_input.name // empty')
SKILL=${SKILL##*:}   # strip a plugin prefix like engineering:code-review
[ -z "$SKILL" ] && exit 0

case "$SKILL" in
  code-review|security-review|simplify)
    mk_write "review-$SKILL" "{\"skill\":\"$SKILL\"}" ;;
  emil-design-eng|impeccable|frontend-design|web-interface-guidelines)
    mk_write design "{\"skill\":\"$SKILL\"}" ;;
esac
exit 0
