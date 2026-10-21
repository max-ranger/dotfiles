#!/bin/bash
# Record test runs for the verify gate. Two hook events, one tool call:
#   PreToolUse (Bash), `track-tests.sh start`: notes when the command starts.
#   PostToolUse (Bash): records the run, stamped with that start time, under the repo
#   it ran in (the session cwd, followed through `cd`/`pushd`).
# PostToolUse only sees commands that exited 0 (a failure goes to PostToolUseFailure),
# so a run counts when its own failure would have failed the whole command: a test
# runner at a command position (quoted text is data), followed only by `&&`, or by
# pipes under `set -o pipefail` in the same shell. `npm test | tail`, `npm test; echo`,
# `npm test || true`, `npm test &` and `echo $(npm test)` hide the runner's exit status
# and are not recorded, nor is a run after a `cd` to a path held in a variable.
INPUT=$(cat)
case $INPUT in *test*|*jest*|*pytest*|*phpunit*|*rspec*) ;; *) exit 0 ;; esac
# the cheap check again, on the command alone (the JSON also holds paths and stdout)
case $(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null) in
  *test*|*jest*|*pytest*|*phpunit*|*rspec*) ;; *) exit 0 ;;
esac
source "$(dirname "$0")/_markers.sh"
mk_init "$INPUT"
[ -n "$MK_DIR" ] || exit 0
ID=$(printf '%s' "$INPUT" | _j '.tool_use_id // empty' | tr -cd 'A-Za-z0-9_-')

if [ "${1:-}" = start ]; then
  [ -n "$ID" ] && jq -n now > "$MK_DIR/test-start-$ID" 2>/dev/null
  # notes of runs that never reached PostToolUse (denied, or failed)
  find "$MK_DIR" -name 'test-start-*' -mtime +1 -delete 2>/dev/null
  exit 0
fi
# this call's start note, read and removed whether or not it turns out to be a test run
START=""
if [ -n "$ID" ] && [ -f "$MK_DIR/test-start-$ID" ]; then
  START=$(cat "$MK_DIR/test-start-$ID"); rm -f "$MK_DIR/test-start-$ID"
fi

# ranger: shortcut — quotes are blanked by regex, not tokenized like _git-cmd.sh does;
# heredoc bodies stay text. A runner the pattern misses costs one verify-gate block.
read -r -d '' PROG <<'JQ'
  def ws: "[ \\t]+";
  def runner: "(?:(?:pnpm|npm|yarn|bun)(?:" + ws + "[^;&|\\n]*)?" + ws + "test(?::[\\w:-]+)?"
    + "|vitest|jest|(?:dotnet|flutter|dart|go|cargo|playwright)" + ws + "test|pytest|phpunit|rspec)";
  def launcher: "(?:npx|bunx|fvm|xvfb-run|(?:pnpm|yarn|bun)(?:" + ws + "(?:exec|dlx))?"
    + "|python3?" + ws + "-m|(?:uv|poetry)" + ws + "run)" + ws;
  def prefix: "(?:[A-Za-z_]\\w*=[^ \\t;&|]*" + ws + "|(?:time|env|command|nohup|timeout" + ws + "[\\w.]+)" + ws + ")*(?:" + launcher + ")?";
  # closed ( ) groups as same-length filler: a set or cd inside one is gone after it
  def flat: gsub("(?<p>\\((?:[^()]|\\g<p>)*\\))"; "_" * (.p | length));
  # is the runner matched by $m followed by anything that would swallow its failure?
  def hidden($c; $m):
    ($c[:$m.offset] | flat | test("set" + ws + "-[A-Za-z]*o" + ws + "pipefail")) as $pipefail
    | $c[($m.offset + $m.length):]
    | gsub("[0-9]*>&[0-9-]*"; "") | gsub("&>"; "") | gsub("&&"; " ")
    | if $pipefail then gsub("(?<!\\|)\\|(?!\\|)"; " ") else . end
    | test("[;&|\\n]");
  .tool_input.command // "" | . as $raw
  | gsub("(?<q>'[^']*'|\"(?:[^\"\\\\]|\\\\.)*\")"; .q[:1] + "_" * (.q | length - 2) + .q[-1:])
  | . as $c
  | [match("(?:^|[;&|\\n]|(?<![$<])\\()[ \\t]*" + prefix + runner + "(?=$|[ \\t;&|)<>\\n])"; "g")]
  | select(length > 0 and (map(hidden($c; .)) | any | not))
  | last as $m
  # line 1: the command; then every cd/pushd target on the way to the last runner
  | ($raw[:120] | tojson),
    ($c[:$m.offset] | flat
     | match("(?:^|[;&|(\\n])[ \\t]*(?:cd|pushd)(?:" + ws + "(\\S+))?(?=$|[ \\t;&|)\\n])"; "g")
     | .captures[0]
     | if .string == null then "~"
       else $raw[.offset:(.offset + .length)]
         | if test("^(['\"]).*['\"]$") then .[1:-1] else . end
       end)
JQ
OUT=$(printf '%s' "$INPUT" | jq -r "$PROG" 2>/dev/null | tr -d '\r')
[ -n "$OUT" ] || exit 0

DIR=$MK_CWD
while IFS= read -r t; do
  case $t in
    '$HOME'|'$HOME/'*) t=$HOME${t#\$HOME} ;;
    '${HOME}'|'${HOME}/'*) t=$HOME${t#\$\{HOME\}} ;;
  esac
  case $t in
    '~'|'~/'*) DIR=$HOME${t#\~} ;;
    /*|[A-Za-z]:[\\/]*) DIR=$t ;;
    *) DIR=$DIR/$t ;;
  esac
done < <(printf '%s\n' "$OUT" | tail -n +2)
# a cd to $VAR or - names no real folder: nothing is recorded
REPO=$(git -C "$DIR" rev-parse --show-toplevel 2>/dev/null) || exit 0

KEY=$(printf '%s' "$REPO" | cksum | cut -d' ' -f1)
mk_write "tests-$KEY" "$(jq -nc --argjson c "$(printf '%s\n' "$OUT" | head -1)" --arg r "$REPO" --arg ts "$START" \
  '{command:$c,repo:$r} + (if $ts == "" then {} else {ts:($ts | tonumber)} end)')"
exit 0
