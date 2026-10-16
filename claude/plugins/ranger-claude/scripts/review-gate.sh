#!/bin/bash
# PreToolUse (Bash, `git commit`): deny the commit until /code-review ran against the
# current HEAD (i.e. since the last commit) in a session. Docs-only commits pass.
# Every `git … commit` in the command is checked in the repo it targets (git -C <repo>,
# cd <repo> &&) against that repo's marker: a review recorded for the session's repo
# does not count for a commit in another one.
# Emergency bypass: RANGER_SKIP_REVIEW=1 git commit ...
INPUT=$(cat)
source "$(dirname "$0")/_markers.sh"
source "$(dirname "$0")/_git-cmd.sh"
mk_init "$INPUT"
CMD=$(printf '%s' "$INPUT" | _j '.tool_input.command // empty')
[ -z "$CMD" ] && exit 0
gc_parse "$CMD" "$MK_CWD"
COMMITS=$(gc_find commit)
[ -z "$COMMITS" ] && exit 0
printf '%s' "$CMD" | grep -qE '(^|[;&| ])RANGER_SKIP_REVIEW=1' && exit 0
SESSION_GITDIR=$MK_GITDIR

for i in $COMMITS; do
  gc_opts "$i"; mk_repo "${GC_OPTS[@]}"
  [ -n "$MK_DIR" ] || continue

  STAGED=$(gc_git "$i" diff --cached --name-only 2>/dev/null)
  # `git commit -a` stages tracked changes at commit time: include them.
  gc_flag "$i" a --all && STAGED="$STAGED"$'\n'"$(gc_git "$i" diff --name-only 2>/dev/null)"
  CODE=$(printf '%s\n' "$STAGED" | while IFS= read -r f; do [ -n "$f" ] && mk_is_code "$f" && printf '%s\n' "$f"; done)
  [ -z "$CODE" ] && continue

  REVIEWED_HEAD=$(mk_field review-code-review head)
  [ "$REVIEWED_HEAD" = "$MK_HEAD" ] && continue

  N=$(printf '%s\n' "$CODE" | grep -c .)
  WHERE=""
  [ "$MK_GITDIR" != "$SESSION_GITDIR" ] && WHERE=" in $(gc_git "$i" rev-parse --show-toplevel 2>/dev/null), which is not this session's repo (a review counts only for the repo of the session that ran it: commit from a session there),"
  jq -nc --arg n "$N" --arg w "$WHERE" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",
    permissionDecisionReason:("Review gate: " + $n + " source file(s) staged" + $w + " and no /code-review has run since the last commit. Run /simplify (optional) and then /code-review on the current diff, fix the blocking findings, then commit again. Docs-only commits are exempt; RANGER_SKIP_REVIEW=1 bypasses in an emergency.")}}'
  exit 0
done
exit 0
