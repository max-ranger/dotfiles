#!/bin/bash
# PreToolUse (Bash, `git commit`): deny the commit until /code-review ran against the
# current HEAD (i.e. since the last commit) in a session. Docs-only commits pass.
# Every `git … commit` in the command is checked in the repo it targets (git -C <repo>,
# cd <repo> &&) against that repo's marker: a review recorded for the session's repo
# does not count for a commit in another one.
# Emergency bypass, the person's alone: launch Claude Code with RANGER_SKIP_REVIEW=1 in
# its environment (hooks inherit it). The variable written into a command, or into the
# `env` of a settings file the agent can edit, does nothing: else the agent could wave
# its own commits through.
INPUT=$(cat)
if [ "${RANGER_SKIP_REVIEW:-}" = 1 ]; then
  P=${CLAUDE_PROJECT_DIR:-$PWD}
  FROM_SETTINGS=""
  for f in "$HOME/.claude/settings.json" "$HOME/.claude/settings.local.json" \
           "$P/.claude/settings.json" "$P/.claude/settings.local.json"; do
    [ -f "$f" ] && jq -e '.env.RANGER_SKIP_REVIEW // empty' "$f" >/dev/null 2>&1 && FROM_SETTINGS=1
  done
  [ -z "$FROM_SETTINGS" ] && exit 0
fi
source "$(dirname "$0")/_markers.sh"
source "$(dirname "$0")/_git-cmd.sh"
mk_init "$INPUT"
CMD=$(printf '%s' "$INPUT" | _j '.tool_input.command // empty')
[ -z "$CMD" ] && exit 0
gc_parse "$CMD" "$MK_CWD"
COMMITS=$(gc_find commit)
[ -z "$COMMITS" ] && exit 0
SESSION_GITDIR=$MK_GITDIR

for i in $COMMITS; do
  gc_opts "$i"; mk_repo "${GC_OPTS[@]}"
  [ -n "$MK_DIR" ] || continue

  # the index plus what an earlier `git add` or `commit -a` adds to it at commit time
  STAGED=$( { gc_git "$i" diff --cached --name-only 2>/dev/null; gc_pending "$i"; } | sort -u)
  CODE=$(printf '%s\n' "$STAGED" | while IFS= read -r f; do [ -n "$f" ] && mk_is_code "$f" && printf '%s\n' "$f"; done)
  [ -z "$CODE" ] && continue

  REVIEWED_HEAD=$(mk_field review-code-review head)
  [ "$REVIEWED_HEAD" = "$MK_HEAD" ] && continue

  N=$(printf '%s\n' "$CODE" | grep -c .)
  WHERE=""
  [ "$MK_GITDIR" != "$SESSION_GITDIR" ] && WHERE=" in $(gc_git "$i" rev-parse --show-toplevel 2>/dev/null), which is not this session's repo (a review counts only for the repo of the session that ran it: commit from a session there),"
  jq -nc --arg n "$N" --arg w "$WHERE" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",
    permissionDecisionReason:("Review gate: " + $n + " source file(s) staged" + $w + " and no /code-review has run since the last commit. Run /simplify (optional) and then /code-review on the current diff, fix the blocking findings, then commit again. Docs-only commits are exempt. Only Max can bypass this gate, by launching Claude Code with RANGER_SKIP_REVIEW=1; setting it in the command does nothing.")}}'
  exit 0
done
exit 0
