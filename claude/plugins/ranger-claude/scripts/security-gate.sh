#!/bin/bash
# Blocks dangerous shell commands (PreToolUse Bash).

source "$(dirname "$0")/_parse-input.sh"
source "$(dirname "$0")/_git-cmd.sh"
[ -z "$HOOK_COMMAND" ] && exit 0

emit() {
  local decision="$1" reason="$2"
  reason=${reason//\\/\\\\}
  reason=${reason//\"/\\\"}
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"%s"}}\n' "$decision" "$reason"
  # exit 0 so Claude Code honors the JSON permissionDecision (allow/ask/deny).
  # exit 2 would force a hard block and read stderr (empty here) instead,
  # silently swallowing every ask/deny — which is the bug this replaces.
  exit 0
}
deny() { emit deny "DANGER: $1"; }
# An ask waits until every check has run, so a deny later in the command still wins.
ASK=""
ask()  { [ -n "$ASK" ] || ASK="$1"; }

C="$HOOK_COMMAND"
# Every git invocation in the command, with the repo it targets (git -C, cd …&&).
gc_parse "$C" "$HOOK_CWD"

# ── Git push protections ──
# A repo with a develop branch takes main only through release PRs (develop → main, merged on GitHub once the release
# gate is green): a push to main is denied there. Elsewhere it is asked.
uses_develop() { gc_git "$1" show-ref --verify --quiet refs/heads/develop || gc_git "$1" show-ref --verify --quiet refs/remotes/origin/develop; }
for i in $(gc_find push); do
  # refspecs: the arguments that are neither options nor option values, after the
  # remote (which --repo names instead)
  gc_argv "$i"; POS=(); SKIP=0; REPO=0
  for a in "${GC_ARGV[@]}"; do
    if [ "$SKIP" = 1 ]; then SKIP=0
    else
      case $a in
        --repo) SKIP=1; REPO=1 ;;
        --repo=*) REPO=1 ;;
        -o|--push-option|--receive-pack|--exec) SKIP=1 ;;
        -*) ;;
        *) POS+=("$a") ;;
      esac
    fi
  done
  [ "$REPO" = 1 ] || POS=("${POS[@]:1}")
  FORCE=0; TO_MAIN=0; CURRENT=0
  gc_flag "$i" f --force && ! gc_flag "$i" '' --force-with-lease && FORCE=1
  gc_flag "$i" '' --mirror && FORCE=1                # force-updates and deletes remote refs
  gc_flag "$i" '' --all --branches && TO_MAIN=1      # every branch, main included
  # nothing named (no refspec, no --all/--mirror/--tags): pushes the current branch
  [ ${#POS[@]} -eq 0 ] && ! gc_flag "$i" '' --all --branches --mirror --tags && CURRENT=1
  for r in "${POS[@]}"; do
    case $r in +*) FORCE=1; r=${r#+} ;; esac       # +refspec force-pushes that ref
    r=${r##*:}; r=${r#refs/heads/}
    case $r in main|master) TO_MAIN=1 ;; HEAD) CURRENT=1 ;; esac
  done
  [ "$FORCE" = 1 ] && deny "force push blocked. Use --force-with-lease."
  # A variable or `cd -` hides the repo: the session's repo would be the wrong one to judge (deny or allow by
  # accident), so the push is asked.
  if ! gc_known "$i" && { [ "$TO_MAIN" = 1 ] || [ "$CURRENT" = 1 ]; }; then
    ask "this push's repo is not known before it runs (a variable or cd - on the way to it), so its develop branch cannot be checked. A repo with develop takes main only through release PRs. Confirm the push?"
    continue
  fi
  if [ "$TO_MAIN" = 1 ]; then
    uses_develop "$i" && deny "pushing to main in a repo with a develop branch: main only takes release PRs from develop. Push to develop (or a branch) and open a release PR."
    ask "pushing to main/master. Fine for personal repos; use a branch + PR for shared/client repos. Confirm?"
  fi
  if [ "$CURRENT" = 1 ]; then
    CB=$(gc_git "$i" branch --show-current 2>/dev/null)
    if [ "$CB" = "main" ] || [ "$CB" = "master" ]; then
      uses_develop "$i" && deny "you are on $CB in a repo with a develop branch: main only takes release PRs from develop. Switch to develop."
      ask "you are on $CB. Confirm push?"
    fi
  fi
done

# ── rm -rf on broad paths ──
if echo "$C" | grep -qE 'rm[[:space:]]+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r)[[:space:]]+(/([[:space:]]|$|\*)|~/?(\*|$|[[:space:]])|\$HOME|\.\./\.\.)'; then
  deny "rm -rf on root/home/parent blocked."
fi

# ── Git destructive (ask first) ──
# Each also keeps its loose text match from before the parser: an ask costs one
# confirmation, and the match covers what the parser does not follow
# (`xargs git branch -D`, `sudo git reset --hard`), quoted text included.
RESET="git reset --hard discards uncommitted work. Confirm?"
CLEAN="git clean -f permanently deletes untracked files. Confirm?"
BRANCH_D="git branch -D force-deletes unmerged branch. Confirm?"
for i in $(gc_find reset); do gc_flag "$i" '' --hard && ask "$RESET"; done
for i in $(gc_find clean); do gc_flag "$i" f --force && ask "$CLEAN"; done
for i in $(gc_find branch); do
  if gc_flag "$i" D || { gc_flag "$i" d --delete && gc_flag "$i" f --force; }; then ask "$BRANCH_D"; fi
done
echo "$C" | grep -qE 'git[[:space:]]+reset[[:space:]]+--hard' && ask "$RESET"
echo "$C" | grep -qE 'git[[:space:]]+clean[[:space:]]+-[a-zA-Z]*f' && ask "$CLEAN"
echo "$C" | grep -qE 'git[[:space:]]+branch[[:space:]]+-D' && ask "$BRANCH_D"

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

[ -n "$ASK" ] && emit ask "DANGER: $ASK"
exit 0
