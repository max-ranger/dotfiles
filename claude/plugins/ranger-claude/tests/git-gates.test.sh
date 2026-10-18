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
# package.json whose tests fail with two lines of output (pre-commit: deny, as valid JSON) staged.
R="$T/tar get"
git init -q -b main "$R"
echo r > "$R/README.md"
git -C "$R" add README.md && git -C "$R" commit -qm init && git -C "$R" branch develop
echo 'SECRET=1' > "$R/.env"; : > "$R/.DS_Store"; echo 'export const a = 1' > "$R/app.ts"
echo '{"scripts":{"test":"echo first line; echo second line; exit 1"}}' > "$R/package.json"
git -C "$R" add -f .env .DS_Store app.ts package.json

# A: nothing staged; what a `git add` in the command would bring is in the worktree:
# a .env, a .DS_Store, app.ts, new.js with a token, a modified config.js with a key,
# docs.md, sub/page.ts, and a deleted id.pem (removing a key file is not staging one). Its eslint always fails, so pre-commit denies any staged JS/TS.
# The secret literals are built at run time so this file does not trip the secret scan.
A="$T/adds"
git init -q -b feature "$A"
printf 'node_modules/\n' > "$A/.gitignore"; echo '{"name":"a"}' > "$A/package.json"
echo 'export default {}' > "$A/config.js"; echo a > "$A/README.md"; echo k > "$A/id.pem"
git -C "$A" add -A && git -C "$A" commit -qm init && rm "$A/id.pem"
mkdir -p "$A/sub" "$A/node_modules/.bin"
printf '#!/bin/sh\nexit 1\n' > "$A/node_modules/.bin/eslint"; chmod +x "$A/node_modules/.bin/eslint"
printf 'export const aws = "%s%s"\n' AKIA ABCDEFGHIJKLMNOP >> "$A/config.js"
printf 'export const t = "%s%s"\n' ghp_ abcdefghijklmnopqrstuvwxyz0123 > "$A/new.js"
echo 'SECRET=1' > "$A/.env"; : > "$A/.DS_Store"; echo 'export const a = 1' > "$A/app.ts"
echo '# notes' > "$A/docs.md"; echo 'export const p = 1' > "$A/sub/page.ts"

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

# ── push to a repo the parser cannot resolve (a variable, cd -): ask, never judge the session's repo ──
expect "loop var -C push main, session R"   "$R" "for d in '$S'; do git -C \$d push origin main; done" ask - - - -
expect "-C \"\$X\" push main, session R"      "$R" "git -C \"\$X\" push origin main"          ask - - - -
expect "cd \$X && git push, session R"       "$R" "cd \$X && git push"                       ask - - - -
expect "cd - && git push, session S"        "$S" "cd - && git push"                         ask - - - -
expect "cd \$X && git -C . push main, R"      "$R" "cd \$X && git -C . push origin main"       ask - - - -
expect "cd \$X && git -C R push main"        "$S" "cd \$X && git -C '$R' push origin main"    deny - - - -
expect "cd \$X; cd R && git push main"       "$S" "cd \$X; cd '$R' && git push origin main"   deny - - - -
expect "cd R && git push origin main"       "$S" "cd '$R' && git push origin main"          deny - - - -
expect "(cd \$X && …); git push main, R"     "$R" "(cd \$X && git status); git push origin main" deny - - - -
expect "-C \$X push --force"                 "$S" "git -C \$X push --force"                  deny - - - -
expect "-C \$X push origin feature"          "$S" "git -C \$X push origin feature"           allow - - - -
expect "--git-dir=\$G push main, session R"   "$R" "git --git-dir=\$G push origin main"        ask - - - -
expect "cd \$X && --git-dir=R push main"     "$S" "cd \$X && git --git-dir='$R/.git' push origin main" deny - - - -
expect "cd \$X && bash -c push main, R"      "$R" "cd \$X && bash -c 'git push origin main'"  ask - - - -
expect "cd \$X && bash <<EOF push main, R"   "$R" "cd \$X && bash <<'EOF'
git push origin main
EOF"                                                                                   ask - - - -
expect "cd \$X && eval push main, R"         "$R" "cd \$X && eval git push origin main"       ask - - - -
expect "cd \$X && \$(push main), R"           "$R" "cd \$X && echo \$(git push origin main)"   ask - - - -
HOME="$R" \
expect "cd \$X; cd && push main, HOME=R"     "$S" "cd \$X; cd && git push origin main"        deny - - - -

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

# ── git add … && git commit: judged on what the add stages, not the index before it ──
expect "A: nothing staged"                  "$A" "git commit -m x"                         allow allow allow allow allow
expect "A: add -A && commit"                "$A" "git add -A && git commit -m x"           allow deny ask deny deny
expect "A: add docs.md && commit"           "$A" "git add docs.md && git commit -m x"      allow allow allow allow allow
expect "A: add modified config.js (key)"    "$A" "git add config.js && git commit -m x"    allow ask allow deny deny
expect "A: add new.js (token, new file)"    "$A" "git add new.js; git commit -m x"         allow ask allow deny deny
expect "A: stage .DS_Store && commit"       "$A" "git stage .DS_Store && git commit -m x"  allow allow ask allow allow
expect "A: cd sub && add . && commit"       "$A" "cd sub && git add . && git commit -m x"  allow allow allow deny deny
expect "A: commit -am (tracked config.js)"  "$A" "git commit -am x"                        allow ask allow deny deny
expect "A: add -u (id.pem deleted)"         "$A" "git add -u && git commit -m x"           allow ask allow deny deny
expect "A: add after the commit"            "$A" "git commit -m x && git add -A"           allow allow allow allow allow
expect "A: add in another repo"             "$A" "git -C '$S' add -A && git commit -m x"   allow allow allow allow allow
expect "A from S: -C add -A && -C commit"   "$S" "git -C '$A' add -A && git -C '$A' commit -m x" allow deny ask deny allow
# another git process (an IDE, a parallel gate) holds A's index.lock: same decisions
: > "$A/.git/index.lock"
expect "A: add -A && commit, index locked"  "$A" "git add -A && git commit -m x"           allow deny ask deny deny
rm -f "$A/.git/index.lock"
# the gates run in parallel in Claude Code
for g in secure-commits commit-hygiene review-gate pre-commit-checks; do
  decide "$g" "$A" "git add -A && git commit -m x" > "$T/par.$g" &
done
wait
for g in secure-commits:deny commit-hygiene:ask review-gate:deny pre-commit-checks:deny; do
  got=$(cat "$T/par.${g%%:*}")
  if [ "$got" = "${g#*:}" ]; then PASS=$((PASS + 1))
  else FAIL=$((FAIL + 1)); printf 'FAIL  %-44s %-18s want %-5s got %s\n' "A: gates in parallel" "${g%%:*}" "${g#*:}" "$got"; fi
done
# `git add -e` must not open an editor from a hook: this one leaves a marker and fails
export GIT_EDITOR="touch '$T/editor-ran'; false"
expect "A: add -e && commit"                "$A" "git add -e && git commit -m x"           allow allow allow allow allow
unset GIT_EDITOR
if [ ! -e "$T/editor-ran" ]; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); echo "FAIL  a gate opened an editor for git add -e"; fi
STAGED_AFTER=$(git -C "$A" diff --cached --name-only)
if [ -z "$STAGED_AFTER" ]; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); echo "FAIL  the gates changed A's real index: $STAGED_AFTER"; fi

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

# ── .NET: dotnet test runs in the solution folder above each staged C#/MSBuild file ──
# D keeps its solutions one level down (like the template's src/backend), in two folders.
# A stub dotnet reads stdin (as a build or test host may), logs the folder it ran in and
# its arguments, prints a stack frame and a Windows path, and exits with $DOTNET_STUB_EXIT.
D="$T/dot net"
git init -q -b feature "$D"
mkdir -p "$D/backend/App" "$D/tools" "$T/stub"
echo '<Solution />' > "$D/backend/App.slnx"; echo 'class A {}' > "$D/backend/App/A.cs"
echo '<Solution />' > "$D/tools/Tools.slnx"; echo 'class T {}' > "$D/tools/T.cs"
echo 'root = true' > "$D/backend/.editorconfig"; echo d > "$D/README.md"
git -C "$D" add -A && git -C "$D" commit -qm init
cat > "$T/stub/dotnet" <<EOF
#!/bin/sh
cat > /dev/null
echo "\$(pwd -P) \$*" >> "$T/dotnet-ran"
echo "  Failed Probe_fails [1 ms]"
echo "   at Probe.Fails() in /src/ProbeTests.cs:line 3"
printf '%s\n' 'C:\Dev\tests\X.cs(3,1): error CS1002'
exit "\${DOTNET_STUB_EXIT:-0}"
EOF
chmod +x "$T/stub/dotnet"
OLD_PATH=$PATH; PATH="$T/stub:$PATH"
ran_in() {  # ran_in <label> <folder>... | none: the folders the stub ran in (with `test`) since the last check
  local label=$1 want='' got='' d; shift
  if [ "$1" != none ]; then for d in "$@"; do want+="$(cd "$d" && pwd -P) test"$'\n'; done; fi
  [ -f "$T/dotnet-ran" ] && got=$(sort "$T/dotnet-ran")$'\n'
  want=$(printf '%s' "$want" | sort)$'\n'; [ "$want" = $'\n' ] && want=''
  if [ "$got" = "$want" ]; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); printf 'FAIL  %s: dotnet ran\n%swant\n%s' "$label" "$got" "$want"; fi
  rm -f "$T/dotnet-ran"
}
reason_has() {  # reason_has <label> <cwd> <command> <text>...: the deny reason holds each text, no stack frame
  local label=$1 out t; out=$(cd "$2" && jq -nc --arg c "$3" --arg d "$2" \
    '{session_id:"test",cwd:$d,hook_event_name:"PreToolUse",tool_name:"Bash",tool_input:{command:$c}}' \
    | bash "$SCRIPTS/pre-commit-checks.sh" 2>/dev/null | jq -r '.hookSpecificOutput.permissionDecisionReason')
  shift 3; rm -f "$T/dotnet-ran"
  for t in "$@"; do
    case $out in *"$t"*) PASS=$((PASS + 1)) ;; *) FAIL=$((FAIL + 1)); printf 'FAIL  %s: reason lacks %s:\n%s\n' "$label" "$t" "$out" ;; esac
  done
  case $out in *"at Probe.Fails"*) FAIL=$((FAIL + 1)); echo "FAIL  $label: stack frame kept in the reason" ;; *) PASS=$((PASS + 1)) ;; esac
}
echo 'class A { int b; }' > "$D/backend/App/A.cs"
export DOTNET_STUB_EXIT=1
expect "D: commit -am, tests fail"          "$D" "git commit -am x"                        - - - - deny
ran_in "D: commit -am, tests fail" "$D/backend"
reason_has "D: reason names folder and test" "$D" "git commit -am x" "dotnet test failed in backend:" "Failed Probe_fails" 'C:\Dev\tests\X.cs(3,1)'
echo 'class T { int b; }' > "$D/tools/T.cs"
expect "D: two solution folders"            "$D" "git commit -am x"                        - - - - deny
ran_in "D: two solution folders" "$D/backend" "$D/tools"
git -C "$D" checkout -q -- .
rm "$D/backend/App/A.cs"
expect "D: commit -am deleting A.cs"        "$D" "git commit -am x"                        - - - - deny
ran_in "D: commit -am deleting A.cs" "$D/backend"
git -C "$D" checkout -q -- .
echo 'indent_size = 4' >> "$D/backend/.editorconfig"
expect "D: .editorconfig only"              "$D" "git commit -am x"                        - - - - deny
ran_in "D: .editorconfig only" "$D/backend"
git -C "$D" checkout -q -- .; echo changed >> "$D/README.md"
expect "D: README only, no dotnet run"      "$D" "git commit -am x"                        - - - - allow
ran_in "D: README only, no dotnet run" none
echo 'class A { int c; }' > "$D/backend/App/A.cs"
export DOTNET_STUB_EXIT=0
expect "D: commit -am, tests pass"          "$D" "git commit -am x"                        - - - - allow
ran_in "D: commit -am, tests pass" "$D/backend"
unset DOTNET_STUB_EXIT; PATH=$OLD_PATH

echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
