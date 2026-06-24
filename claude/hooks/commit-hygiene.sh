#!/bin/bash
# Asks for confirmation when a `git commit` stages junk or skill-produced
# artifacts (PreToolUse Bash). Ask-only (exit 0 + permissionDecision:ask) so a
# false positive costs one confirmation, never a hard block.

source ~/.claude/hooks/_parse-input.sh
[ -z "$HOOK_COMMAND" ] && exit 0

# Only trigger on git commit
if ! echo "$HOOK_COMMAND" | grep -qE '(^|[;&|()]+[[:space:]]*)git[[:space:]]+commit(\b|$)'; then
  exit 0
fi

ask() {
  local reason="$1"
  reason=${reason//\\/\\\\}
  reason=${reason//\"/\\\"}
  reason=${reason//$'\n'/ }
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' "$reason"
  # exit 0 so the ask is honored (see secure-commits.sh for why not exit 2).
  exit 0
}

STAGED=$(git diff --cached --name-only 2>/dev/null)
[ -z "$STAGED" ] && exit 0

# Patterns that are almost never meant to be committed. Ask-only, so the bar for
# inclusion is "usually a mistake," not "always wrong."
JUNK=$(echo "$STAGED" | grep -iE \
  -e '(^|/)\.DS_Store$' \
  -e '(^|/)Thumbs\.db$' \
  -e '(^|/)desktop\.ini$' \
  -e '\.(log|tmp|temp|swp|swo|orig|bak)$' \
  -e '(^|/)[^/]+~$' \
  -e '(^|/)(scratch|\.scratch|tmp)/' \
  -e '(^|/)(node_modules|coverage|\.next|\.turbo|\.cache)/' \
  -e '(^|/)docs/superpowers/' \
  || true)

if [ -n "$JUNK" ]; then
  LIST=$(echo "$JUNK" | tr '\n' ',' | sed 's/,$//')
  ask "commit stages likely-unwanted file(s): ${LIST}. These look like OS/editor junk, build/dep output, scratch, or skill-produced artifacts (docs/superpowers/* belong in basic-memory, not the repo). Unstage with: git restore --staged <file> — or add to .gitignore. Confirm only if committing them is intended."
fi

exit 0
