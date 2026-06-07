#!/bin/bash
# Blocks dangerous shell commands (PreToolUse Bash).

source ~/.claude/hooks/_parse-input.sh
[ -z "$HOOK_COMMAND" ] && exit 0

emit() {
  local decision="$1" reason="$2"
  reason=${reason//\\/\\\\}
  reason=${reason//\"/\\\"}
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"%s"}}\n' "$decision" "$reason"
  exit 2
}
deny() { emit deny "DANGER: $1"; }
ask()  { emit ask  "DANGER: $1"; }

C="$HOOK_COMMAND"

# ── Git push protections ──
if echo "$C" | grep -qE '(^|[;&|()]+[[:space:]]*)git[[:space:]]+push'; then
  if echo "$C" | grep -qE 'git[[:space:]]+push.*(origin[[:space:]]+|:)(main|master)(\b|$)'; then
    ask "pushing to main/master. Fine for personal repos; use a branch + PR for shared/client repos. Confirm?"
  fi
  if echo "$C" | grep -qE 'git[[:space:]]+push[[:space:]]*($|[;&|])'; then
    CB=$(git branch --show-current 2>/dev/null)
    if [ "$CB" = "main" ] || [ "$CB" = "master" ]; then
      ask "you are on $CB. Confirm push?"
    fi
  fi
  if echo "$C" | grep -qE 'git[[:space:]]+push.*(-[a-zA-Z]*f([[:space:]]|$)|--force([[:space:]]|$))' && ! echo "$C" | grep -q '\-\-force-with-lease'; then
    deny "force push blocked. Use --force-with-lease."
  fi
fi

# ── rm -rf on broad paths ──
if echo "$C" | grep -qE 'rm[[:space:]]+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r)[[:space:]]+(/([[:space:]]|$|\*)|~/?(\*|$|[[:space:]])|\$HOME|\.\./\.\.)'; then
  deny "rm -rf on root/home/parent blocked."
fi

# ── Git destructive (ask first) ──
echo "$C" | grep -qE 'git[[:space:]]+reset[[:space:]]+--hard' && ask "git reset --hard discards uncommitted work. Confirm?"
echo "$C" | grep -qE 'git[[:space:]]+clean[[:space:]]+-[a-zA-Z]*f' && ask "git clean -f permanently deletes untracked files. Confirm?"
echo "$C" | grep -qE 'git[[:space:]]+branch[[:space:]]+-D' && ask "git branch -D force-deletes unmerged branch. Confirm?"

# ── SQL destructive ──
echo "$C" | grep -qiE 'DROP[[:space:]]+(TABLE|DATABASE|SCHEMA)[[:space:]]' && deny "DROP TABLE/DATABASE/SCHEMA blocked."
echo "$C" | grep -qiE 'TRUNCATE[[:space:]]+TABLE' && deny "TRUNCATE TABLE blocked."
if echo "$C" | grep -qiE 'DELETE[[:space:]]+FROM[[:space:]]+[a-zA-Z_.]+[[:space:]]*($|;)' && ! echo "$C" | grep -qiE 'WHERE'; then
  deny "DELETE FROM without WHERE blocked."
fi

# ── System / disk ──
echo "$C" | grep -qE '(mkfs|dd[[:space:]]+if=|>[[:space:]]*/dev/sd|>[[:space:]]*/dev/nvme)' && deny "destructive disk op blocked."
echo "$C" | grep -qE '(curl|wget)[[:space:]][^|]*\|[[:space:]]*(sudo[[:space:]]+)?(bash|sh|zsh)([[:space:]]|$)' && ask "pipe-to-shell. Confirm the source is trusted (e.g. a known install script)?"
echo "$C" | grep -qE 'chmod[[:space:]]+(-R[[:space:]]+)?777' && ask "chmod 777 gives world write+exec. Confirm?"

# ── Accidental publishing ──
echo "$C" | grep -qE '(^|[;&|])[[:space:]]*(npm|yarn|pnpm|bun)[[:space:]]+publish' && deny "package publish blocked. Use CI."
echo "$C" | grep -qE '(^|[;&|])[[:space:]]*cargo[[:space:]]+publish' && deny "cargo publish blocked. Use CI."

exit 0
