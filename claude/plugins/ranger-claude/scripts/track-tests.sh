#!/bin/bash
# PostToolUse (Bash): record test runs for the verify gate.
# PostToolUse only sees commands that exited 0 (a failure goes to PostToolUseFailure),
# so a run counts when its own failure would have failed the whole command: a test
# runner at a command position (quoted text is data), followed only by `&&`, or by
# pipes under `set -o pipefail`. `npm test | tail`, `npm test; echo`, `npm test || true`,
# `npm test &` and `echo $(npm test)` hide the runner's exit status and are not recorded.
INPUT=$(cat)
case $INPUT in *test*|*jest*|*pytest*|*phpunit*|*rspec*) ;; *) exit 0 ;; esac
source "$(dirname "$0")/_markers.sh"
mk_init "$INPUT"
[ -n "$MK_DIR" ] || exit 0

# ranger: shortcut — quotes are stripped by regex, not tokenized like _git-cmd.sh does;
# heredoc bodies stay text. A runner the pattern misses costs one verify-gate block.
read -r -d '' PROG <<'JQ'
  def ws: "[ \\t]+";
  def runner: "(?:(?:pnpm|npm|yarn|bun)(?:" + ws + "[^;&|\\n]*)?" + ws + "test(?::[\\w:-]+)?"
    + "|vitest|jest|(?:dotnet|flutter|dart|go|cargo|playwright)" + ws + "test|pytest|phpunit|rspec)";
  def launcher: "(?:npx|bunx|fvm|xvfb-run|(?:pnpm|yarn|bun)(?:" + ws + "(?:exec|dlx))?"
    + "|python3?" + ws + "-m|(?:uv|poetry)" + ws + "run)" + ws;
  def prefix: "(?:[A-Za-z_]\\w*=[^ \\t;&|]*" + ws + "|(?:time|env|command|nohup|timeout" + ws + "[\\w.]+)" + ws + ")*(?:" + launcher + ")?";
  # is the runner matched by $m followed by anything that would swallow its failure?
  def hidden($c; $m):
    ($c[:$m.offset] | test("set" + ws + "-[A-Za-z]*o" + ws + "pipefail")) as $pipefail
    | $c[($m.offset + $m.length):]
    | gsub("[0-9]*>&[0-9-]*"; "") | gsub("&>"; "") | gsub("&&"; " ")
    | if $pipefail then gsub("(?<!\\|)\\|(?!\\|)"; " ") else . end
    | test("[;&|\\n]");
  .tool_input.command // "" | . as $raw
  | gsub("'[^']*'|\"(?:[^\"\\\\]|\\\\.)*\""; "''")              # one left-to-right pass
  | . as $c
  | [match("(?:^|[;&|\\n]|(?<![$<])\\()[ \\t]*" + prefix + runner + "(?=$|[ \\t;&|)<>\\n])"; "g")]
  | select(length > 0 and (map(hidden($c; .)) | any | not))
  | $raw[:120] | tojson
JQ
SAFE=$(printf '%s' "$INPUT" | jq -r "$PROG" 2>/dev/null | tr -d '\r')
[ -n "$SAFE" ] || exit 0
mk_write tests "{\"command\":$SAFE}"
exit 0
