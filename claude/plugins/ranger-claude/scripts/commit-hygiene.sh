#!/bin/bash
# Asks for confirmation when a `git commit` stages junk or skill-produced
# artifacts (PreToolUse Bash). Ask-only (exit 0 + permissionDecision:ask) so a
# false positive costs one confirmation, never a hard block.

source "$(dirname "$0")/_parse-input.sh"
source "$(dirname "$0")/_git-cmd.sh"
[ -z "$HOOK_COMMAND" ] && exit 0

# Only trigger on git commit: every `git … commit` in the command, checked in the
# repo it targets (git -C <repo>, cd <repo> &&).
gc_parse "$HOOK_COMMAND" "$HOOK_CWD"
COMMITS=$(gc_find commit)
[ -z "$COMMITS" ] && exit 0

ask() {
  local reason="$1"
  reason=${reason//\\/\\\\}
  reason=${reason//\"/\\\"}
  reason=${reason//$'\n'/ }
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' "$reason"
  # exit 0 so the ask is honored (see secure-commits.sh for why not exit 2).
  exit 0
}

for i in $COMMITS; do
  STAGED=$(gc_git "$i" diff --cached --name-only 2>/dev/null)
  [ -z "$STAGED" ] && continue

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
    || true)

  if [ -n "$JUNK" ]; then
    LIST=$(echo "$JUNK" | tr '\n' ',' | sed 's/,$//')
    ask "commit stages likely-unwanted file(s) in ${GC_DIR[$i]}: ${LIST}. These look like OS/editor junk, build/dep output, or scratch files. Unstage with: git restore --staged <file> — or add to .gitignore. Confirm only if committing them is intended."
  fi
done

exit 0
