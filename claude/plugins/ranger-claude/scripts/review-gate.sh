#!/bin/bash
# PreToolUse (Bash, `git commit`): deny the commit until /code-review ran against the
# current HEAD (i.e. since the last commit) in a session. Docs-only commits pass.
# Emergency bypass: RANGER_SKIP_REVIEW=1 git commit ...
INPUT=$(cat)
source "$(dirname "$0")/_markers.sh"
mk_init "$INPUT"
CMD=$(printf '%s' "$INPUT" | _j '.tool_input.command // empty')
[ -z "$CMD" ] && exit 0
printf '%s' "$CMD" | grep -qE '(^|[;&|()]+[[:space:]]*)git[[:space:]]+commit(\b|$)' || exit 0
printf '%s' "$CMD" | grep -qE '(^|[;&| ])RANGER_SKIP_REVIEW=1' && exit 0
[ -n "$MK_DIR" ] || exit 0

STAGED=$(git -C "$MK_CWD" diff --cached --name-only 2>/dev/null)
# `git commit -a` stages tracked changes at commit time: include them.
printf '%s' "$CMD" | grep -qE 'git[[:space:]]+commit[^|;&]*(-a\b|--all\b|-[a-zA-Z]*a[a-zA-Z]*\b)' && \
  STAGED="$STAGED"$'\n'"$(git -C "$MK_CWD" diff --name-only 2>/dev/null)"
CODE=$(printf '%s\n' "$STAGED" | while IFS= read -r f; do [ -n "$f" ] && mk_is_code "$f" && printf '%s\n' "$f"; done)
[ -z "$CODE" ] && exit 0

REVIEWED_HEAD=$(mk_field review-code-review head)
[ "$REVIEWED_HEAD" = "$MK_HEAD" ] && exit 0

N=$(printf '%s\n' "$CODE" | grep -c .)
jq -nc --arg n "$N" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",
  permissionDecisionReason:("Review gate: " + $n + " source file(s) staged and no /code-review has run since the last commit. Run /simplify (optional) and then /code-review on the current diff, fix the blocking findings, then commit again. Docs-only commits are exempt; RANGER_SKIP_REVIEW=1 bypasses in an emergency.")}}'
exit 0
