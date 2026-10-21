#!/bin/bash
# Verify gate: a code edit, then one Bash command as Claude Code reports it after a
# successful run (PostToolUse; a non-zero exit goes to PostToolUseFailure and is never
# seen), then a Stop. A command counts as a test run only when a test runner runs as a
# command and its failure would have failed the whole command.
# Needs bash + jq + git.
#   bash claude/plugins/ranger-claude/tests/verify-gate.test.sh
SCRIPTS="$(cd "$(dirname "$0")/../scripts" && pwd)"
T=$(mktemp -d "${TMPDIR:-/tmp}/ranger-verify.XXXXXX")
trap 'rm -rf "$T"' EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
PASS=0; FAIL=0

V="$T/v repo"
O="$T/other repo"
for r in "$V" "$O"; do
  git init -q -b main "$r"
  echo '{"scripts":{"test":"vitest run"}}' > "$r/package.json"
  echo 'export const a = 1' > "$r/app.ts"
  git -C "$r" add -A && git -C "$r" commit -qm init
done

hook() { # hook <script> <json fields>
  (cd "$V" && jq -nc --arg d "$V" "{session_id:\"test\",cwd:\$d} + $2" | bash "$SCRIPTS/$1.sh" 2>/dev/null)
}
edit() { hook track-edits "{tool_name:\"Edit\",tool_input:{file_path:\"${1:-$V}/app.ts\"}}"; }
# a Bash run as Claude Code reports it: PreToolUse when it starts, PostToolUse when it
# exited 0, both with the same tool_use_id
N=0
start() {
  N=$((N + 1)); ID="toolu_$N"; CMD=$(jq -Rn --arg c "$1" '$c')
  (cd "$V" && jq -nc --arg d "$V" "{session_id:\"test\",cwd:\$d,hook_event_name:\"PreToolUse\",tool_name:\"Bash\",tool_use_id:\"$ID\",tool_input:{command:$CMD}}" \
    | bash "$SCRIPTS/track-tests.sh" start 2>/dev/null)
}
finish() {
  hook track-tests "{hook_event_name:\"PostToolUse\",tool_name:\"Bash\",tool_use_id:\"$ID\",tool_input:{command:$CMD},tool_response:{stdout:\"\",stderr:\"\",interrupted:false}}"
}
ran() { start "$1"; finish; }
stop() {
  local out; out=$(hook verify-gate '{hook_event_name:"Stop"}')
  [ -z "$out" ] && { echo allow; return; }
  printf '%s' "$out" | jq -er '.decision' 2>/dev/null || echo badjson
}
reset() { rm -rf "$V/.git/ranger"; }

# expect <label> <allow|block> <command>: edit, run the command, stop
expect() {
  local got; reset; edit; ran "$3"; got=$(stop)
  if [ "$got" = "$2" ]; then PASS=$((PASS + 1))
  else FAIL=$((FAIL + 1)); printf 'FAIL  %-48s want %-5s got %s\n' "$1" "$2" "$got"; fi
}

# ── a test run whose failure would have failed the command: counts ──
expect "npm test"                                  allow "npm test"
expect "cd && pnpm --filter test"                  allow "cd '$V' && pnpm --filter web test"
expect "flutter test && echo ok"                   allow "flutter test && echo ok"
expect "pipefail, then piped"                      allow "set -o pipefail; flutter test 2>&1 | tail -5"
expect "npx vitest run"                            allow "npx vitest run"
expect "dotnet test 2>&1"                          allow "dotnet test 2>&1"
expect "env prefix, npx playwright test"           allow "CI=1 npx playwright test"
expect "npm run test:unit"                         allow "npm run test:unit"
expect "pnpm vitest run"                           allow "pnpm vitest run"
expect "pnpm exec vitest"                          allow "pnpm exec vitest"
expect "python -m pytest"                          allow "python -m pytest -q"
expect "fvm flutter test"                          allow "fvm flutter test"
expect "set -euo pipefail, then piped"             allow "set -euo pipefail; npm test | tail -3"
expect ">& file, then &&"                          allow "flutter test >& /tmp/out.txt && tail /tmp/out.txt"
expect "subshell"                                  allow "(cd '$V' && npm test)"
expect "redirect without a space"                  allow "npm test>/tmp/log && cat /tmp/log"

# ── the exit status is hidden: a failing run would have looked green ──
expect "piped into tail"                           block "flutter test 2>&1 | tail -1"
expect "followed by ;"                             block "npm test; echo done"
expect "|| true"                                   block "npm test || true"
expect "in the background"                         block "npm test &"
expect "two runners, the first one hidden"         block "flutter test; dart test"
expect "command substitution"                      block "echo \$(npm test)"
expect "process substitution"                      block "diff <(npm test 2>&1) expected.txt"
expect "apostrophe in \"…\", then ; and '…'"        block "npm test -- -t \"it's ok\"; echo 'done'"

# ── a runner named but not run ──
expect "quoted in a grep pattern"                  block "grep -oE '(vitest|jest)' package.json"
expect "single-quoted runner"                      block "grep -cE '(jest)' package.json"
expect "double-quoted runner"                      block "grep -cE \"(jest)\" package.json"
expect "an argument, not a command"                block "cat vitest.config.ts"
expect "a bare word argument"                      block "grep -rl jest src"
expect "echoed string"                             block "echo \"npm test\""

# ── pipefail only counts in the shell that runs the pipe ──
expect "pipefail in a closed subshell"             block "(set -o pipefail); npm test | tail -3"
expect "pipefail and pipe in one subshell"         allow "(set -o pipefail; npm test | tail -3)"

# ── the run must start after the edit landed ──
reset; start "npm test"; edit; finish; got=$(stop)
if [ "$got" = block ]; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); printf 'FAIL  %-48s want block got %s\n' "run started before the edit (parallel)" "$got"; fi
reset; edit; start "npm test"; finish; got=$(stop)
if [ "$got" = allow ]; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); printf 'FAIL  %-48s want allow got %s\n' "edit, then run, same second" "$got"; fi

# ── the run must be in the edited file's repo ──
expect "tests ran in another repo"                 block "cd '$O' && npm test"
expect "cd .. then back into this repo"            allow "cd .. && cd 'v repo' && npm test"
expect "cd in a closed subshell, run here"         allow "(cd '$O' && true) && npm test"
expect "cd to a variable"                          block "cd \"\$X\" && npm test"
reset; edit "$O"; ran "cd '$O' && npm test"; got=$(stop)
if [ "$got" = allow ]; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); printf 'FAIL  %-48s want allow got %s\n' "edit and run both in the other repo" "$got"; fi
reset; edit; ran "npm test"; ran "cd '$O' && npm test"; got=$(stop)
if [ "$got" = allow ]; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); printf 'FAIL  %-48s want allow got %s\n' "run here, then one elsewhere" "$got"; fi

# ── cd via $HOME, start notes, markers from before the repo field ──
OLDHOME=$HOME; export HOME="$T"
expect "cd \"\$HOME/…\" into this repo"              allow "cd \"\$HOME/v repo\" && npm test"
export HOME=$OLDHOME
reset; edit; ran "ls tests"; ran "npm test"; left=$(ls "$V/.git/ranger" | grep -c '^test-start-')
if [ "$left" = 0 ]; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); echo "FAIL  start notes left behind: $left"; fi
reset; edit; jq -c 'del(.repo)' "$V/.git/ranger/last-edit.json" > "$T/le" && mv "$T/le" "$V/.git/ranger/last-edit.json"
ran "npm test"; got=$(stop)
if [ "$got" = allow ]; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); printf 'FAIL  %-48s want allow got %s\n' "last-edit marker without repo" "$got"; fi

# ── nothing ran: two blocks, then it lets go ──
reset; edit
for want in block block allow; do
  got=$(stop)
  if [ "$got" = "$want" ]; then PASS=$((PASS + 1))
  else FAIL=$((FAIL + 1)); printf 'FAIL  %-48s want %-5s got %s\n' "no run: stop budget" "$want" "$got"; fi
done

echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
