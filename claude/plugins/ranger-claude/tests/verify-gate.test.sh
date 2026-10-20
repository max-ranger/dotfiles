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
git init -q -b main "$V"
echo '{"scripts":{"test":"vitest run"}}' > "$V/package.json"
echo 'export const a = 1' > "$V/app.ts"
git -C "$V" add -A && git -C "$V" commit -qm init

hook() { # hook <script> <json fields>
  (cd "$V" && jq -nc --arg d "$V" "{session_id:\"test\",cwd:\$d} + $2" | bash "$SCRIPTS/$1.sh" 2>/dev/null)
}
edit() { hook track-edits "{tool_name:\"Edit\",tool_input:{file_path:\"$V/app.ts\"}}"; }
ran() {
  local c; c=$(jq -Rn --arg c "$1" '$c')
  hook track-tests "{tool_name:\"Bash\",tool_input:{command:$c},tool_response:{stdout:\"\",stderr:\"\",interrupted:false}}"
}
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

# ── nothing ran: two blocks, then it lets go ──
reset; edit
for want in block block allow; do
  got=$(stop)
  if [ "$got" = "$want" ]; then PASS=$((PASS + 1))
  else FAIL=$((FAIL + 1)); printf 'FAIL  %-48s want %-5s got %s\n' "no run: stop budget" "$want" "$got"; fi
done

echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
