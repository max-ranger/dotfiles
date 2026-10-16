#!/bin/bash
# Synthetic-input tests for the git gates: every case pipes a PreToolUse Bash JSON
# into each gate, run from a throwaway session repo, and checks the decision.
# Needs bash + jq + git (npm for the pre-commit test cases).
#   bash claude/plugins/ranger-claude/tests/git-gates.test.sh
SCRIPTS="$(cd "$(dirname "$0")/../scripts" && pwd)"
T=$(mktemp -d "${TMPDIR:-/tmp}/ranger-gates.XXXXXX")
trap 'rm -rf "$T"' EXIT
# The machine's git config (signing, hooks, excludes) stays out of the throwaway repos.
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t

# S: the session's repo, on a feature branch, nothing staged, lib.sh modified (unstaged).
S="$T/session"
git init -q -b feature "$S"
echo 'echo hi' > "$S/lib.sh"
git -C "$S" add lib.sh && git -C "$S" commit -qm init
echo 'echo changed' >> "$S/lib.sh"
# R: the repo a command targets (a space in its path), on main with a develop branch,
# with a .env (secret scan: deny), .DS_Store (hygiene: ask), app.ts (review: deny) and a
# package.json whose tests fail (pre-commit: deny) staged.
R="$T/tar get"
git init -q -b main "$R"
echo r > "$R/README.md"
git -C "$R" add README.md && git -C "$R" commit -qm init && git -C "$R" branch develop
echo 'SECRET=1' > "$R/.env"; : > "$R/.DS_Store"; echo 'export const a = 1' > "$R/app.ts"
echo '{"scripts":{"test":"exit 1"}}' > "$R/package.json"
git -C "$R" add -f .env .DS_Store app.ts package.json

PRE=deny; command -v npm >/dev/null 2>&1 || { PRE=allow; echo "npm not on PATH: pre-commit cases expect allow"; }
GATES="security-gate secure-commits commit-hygiene review-gate pre-commit-checks"
PASS=0; FAIL=0

# decide <gate> <cwd> <command>: allow (no output) | ask | deny | badjson | exit<n>
decide() {
  local out rc
  out=$(cd "$2" && jq -nc --arg c "$3" --arg d "$2" \
    '{session_id:"test",cwd:$d,hook_event_name:"PreToolUse",tool_name:"Bash",tool_input:{command:$c}}' \
    | bash "$SCRIPTS/$1.sh" 2>/dev/null)
  rc=$?
  [ "$rc" -eq 0 ] || { echo "exit$rc"; return; }
  [ -z "$out" ] && { echo allow; return; }
  printf '%s' "$out" | jq -er '.hookSpecificOutput.permissionDecision' 2>/dev/null || echo badjson
}

# expect <label> <cwd> <command> <decision per gate, in $GATES order; - skips it>
expect() {
  local label=$1 cwd=$2 cmd=$3 g want got; shift 3
  for g in $GATES; do
    want=$1; shift
    [ "$want" = - ] && continue
    got=$(decide "$g" "$cwd" "$cmd")
    if [ "$got" = "$want" ]; then PASS=$((PASS + 1))
    else FAIL=$((FAIL + 1)); printf 'FAIL  %-44s %-18s want %-5s got %s\n' "$label" "$g" "$want" "$got"; fi
  done
}
# evaluated against R; lint/tests only run when R is the session's own repo
r_commit() { local p=allow; [ "$2" = "$R" ] && p=$PRE; expect "$1" "$2" "$3" allow deny ask deny "$p"; }
s_commit() { expect "$1" "$2" "$3" allow allow allow allow allow; } # evaluated against S

# ── commits: every form decides like the plain one, against the repo it targets ──
r_commit "plain commit in R"                "$R" "git commit -m x"
s_commit "plain commit in S"                "$S" "git commit -m x"
r_commit "git -C R commit"                  "$S" "git -C '$R' commit -m x"
s_commit "git -C S commit from R"           "$R" "git -C '$S' commit -m x"
r_commit "git -C ../R (relative) commit"    "$S" "git -C '../tar get' commit -m x"
r_commit "git -c k=v commit"                "$R" "git -c commit.gpgsign=false commit -m x"
r_commit "git -C R -c k=v --no-pager commit" "$S" "git -C \"$R\" -c a.b=c --no-pager commit -m x"
r_commit "cd R && git commit"               "$S" "cd \"$R\" && git commit -m x"
r_commit "commit in second half"            "$S" "git status && git -C '$R' commit -m x"
r_commit "(cd R && git commit); …"          "$S" "(cd '$R' && git commit -m x); git status"
s_commit "(cd R && …); git commit stays S"  "$S" "(cd '$R' && git status); git commit -m x"
r_commit "--git-dir/--work-tree commit"     "$S" "git --git-dir='$R/.git' --work-tree='$R' commit -m x"
r_commit "bash -c 'git -C R commit'"        "$S" "bash -c \"git -C '$R' commit -m x\""
r_commit "heredoc message naming git push"  "$S" "git -C '$R' commit -m \"\$(cat <<'EOF'
fix: a commit
git push --force origin main
EOF
)\""
r_commit "heredoc message with it's (parens)" "$S" "git -C '$R' commit -m \"\$(cat <<'EOF'
fix: it's (still) a commit
EOF
)\" && git status"
r_commit "commit -F - <<EOF naming a push"  "$S" "git -C '$R' commit -F - <<EOF
git -C '$R' push --force
EOF"
r_commit "commit -F - <<-EOF (tabbed end)"  "$S" "git -C '$R' commit -F - <<-EOF
git push --force
	EOF
git status"
expect "cat <<EOF > file: body is data"     "$S" "cat > notes.md <<'EOF'
git -C '$R' push --force
EOF"                                                                                   allow - - - -
r_commit "commit inside \$( )"              "$S" "out=\$(git -C '$R' commit -m x)"
s_commit "unknown \$VAR falls back to cwd"  "$S" "git -C \"\$NOPE\" commit -m x"
s_commit "negative: echo \"git commit\""    "$R" "echo \"git commit -m x\""
expect "commit -a counts unstaged lib.sh"   "$S" "git commit -am x" - - - deny -
expect "commit without -a: lib.sh unstaged" "$S" "git commit -m x"  - - - allow -

# ── push: force, main, current branch, against the repo it targets ──
expect "plain push --force"                 "$S" "git push --force"                        deny - - - -
expect "git -C R push --force"              "$S" "git -C '$R' push --force"                 deny - - - -
expect "git -C R push +refspec"             "$S" "git -C '$R' push origin +feature"         deny - - - -
expect "git -C R push --force-with-lease"   "$S" "git -C '$R' push --force-with-lease origin feature" allow - - - -
expect "plain push from S (feature)"        "$S" "git push"                                allow - - - -
expect "plain push from R (main, develop)"  "$R" "git push"                                deny - - - -
expect "git -C R push (main, develop)"      "$S" "git -C '$R' push"                         deny - - - -
expect "git -C S push from R (feature)"     "$R" "git -C '$S' push"                         allow - - - -
expect "git -C R push origin main"          "$S" "git -C '$R' push origin main"             deny - - - -
expect "git -C S push origin main"          "$R" "git -C '$S' push origin main"             ask - - - -

expect "git -C R push --tags (main)"        "$S" "git -C '$R' push --tags"                  allow - - - -
expect "git -C R push --all (develop)"      "$S" "git -C '$R' push --all"                   deny - - - -
expect "git -C S push --all"                "$R" "git -C '$S' push --all"                   ask - - - -
expect "git -C R push --mirror"             "$S" "git -C '$R' push --mirror"                deny - - - -
expect "push --repo origin main"            "$R" "git -C '$S' push --repo origin main"      ask - - - -
expect "bash <<EOF runs a force push"       "$S" "bash <<'EOF'
git -C '$R' push --force
EOF"                                                                                   deny - - - -
expect "bash <<< runs a force push"         "$S" "bash <<< \"git -C '$R' push --force\""  deny - - - -

# ── destructive asks ──
expect "plain branch -D"                    "$S" "git branch -D x"                         ask - - - -
expect "git -C R branch -D"                 "$S" "git -C '$R' branch -D x"                  ask - - - -
expect "git -C R branch --delete --force"   "$S" "git -C '$R' branch --delete --force x"    ask - - - -
expect "git -C R branch -d"                 "$S" "git -C '$R' branch -d x"                  allow - - - -
expect "plain reset --hard"                 "$S" "git reset --hard"                        ask - - - -
expect "git -C R reset --hard"              "$S" "git -C '$R' reset --hard"                 ask - - - -
expect "git -C R reset --soft"              "$S" "git -C '$R' reset --soft HEAD~1"          allow - - - -
expect "git -C R clean -fd"                 "$S" "git -C '$R' clean -fd"                    ask - - - -
expect "xargs git branch -D (loose match)"  "$S" "git branch --merged | xargs git branch -D" ask - - - -
expect "sudo git reset --hard (loose)"      "$S" "sudo git reset --hard"                   ask - - - -
expect "quoted reset still asks (loose)"    "$S" "echo \"git reset --hard\""               ask - - - -
expect "ask then deny: deny wins"           "$S" "git -C '$S' push origin main; git -C '$R' push --force" deny - - - -
expect "reset --hard in a substitution"     "$S" "echo \"\$(git -C '$R' reset --hard)\""     ask - - - -

# ── review marker belongs to the repo of the session that ran /code-review ──
skill() {
  (cd "$1" && jq -nc --arg d "$1" '{session_id:"test",cwd:$d,tool_name:"Skill",tool_input:{skill:"code-review"}}' \
    | bash "$SCRIPTS/track-skills.sh")
}
skill "$S"
expect "review in S, commit in R"           "$S" "git -C '$R' commit -m x"                  - - - deny -
expect "review in S, commit -a in S"        "$S" "git commit -am x"                        - - - allow -
expect "RANGER_SKIP_REVIEW=1 bypass"        "$S" "RANGER_SKIP_REVIEW=1 git -C '$R' commit -m x" - - - allow -
skill "$R"
expect "review in R, commit in R from S"    "$S" "git -C '$R' commit -m x"                  - - - allow -

echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
