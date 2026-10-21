#!/bin/bash
# Shared helper for the gate hooks: per-repo marker files under .git/ranger/
# (never committed, per worktree). Each marker is a one-line JSON object.
#
#   source "$(dirname "$0")/_markers.sh"
#   HOOK_INPUT=$(cat); mk_init "$HOOK_INPUT"      # sets MK_DIR, MK_SESSION, MK_CWD, MK_HEAD
#   mk_repo -C /other/repo                          # re-points MK_GITDIR, MK_DIR, MK_HEAD
#   mk_write review '{"skill":"code-review"}'      # adds head/session/ts (sub-second) automatically
#   mk_read  review                                 # prints the JSON or nothing
#   mk_field review head                            # prints one field or nothing
#
# jq is required (it already is for every other hook). Values are CR-stripped
# because the Windows jq build emits CRLF.

_j() { jq -r "$1" 2>/dev/null | tr -d '\r'; }

mk_init() {
  local input="$1"
  MK_SESSION=$(printf '%s' "$input" | _j '.session_id // empty')
  MK_CWD=$(printf '%s' "$input" | _j '.cwd // empty')
  [ -z "$MK_CWD" ] && MK_CWD="$PWD"
  mk_repo -C "$MK_CWD"
  export MK_SESSION MK_CWD MK_GITDIR MK_DIR MK_HEAD
}

# Point the markers at the repo that `git <options>` selects: mk_init passes the
# session cwd, the review gate the repo a `git -C … commit` targets (_git-cmd.sh).
mk_repo() {
  MK_GITDIR=$(git "$@" rev-parse --absolute-git-dir 2>/dev/null)
  MK_DIR=""
  if [ -n "$MK_GITDIR" ]; then
    MK_DIR="$MK_GITDIR/ranger"
    mkdir -p "$MK_DIR" 2>/dev/null
  fi
  MK_HEAD=$(git "$@" rev-parse HEAD 2>/dev/null || echo "none")
}

mk_write() {
  local name="$1" extra="${2:-{\}}"
  [ -n "$MK_DIR" ] || return 0
  # ts: seconds with microseconds (jq's clock), so the verify gate can order an edit
  # and a test run that land in the same second. A ts in $2 wins (track-tests passes
  # the time a run started).
  jq -nc --arg h "$MK_HEAD" --arg s "$MK_SESSION" --argjson x "$extra" \
    '{head:$h,session:$s,ts:now} + $x' > "$MK_DIR/$name.json" 2>/dev/null
}

mk_read() { [ -n "$MK_DIR" ] && [ -f "$MK_DIR/$1.json" ] && cat "$MK_DIR/$1.json"; }
mk_field() { mk_read "$1" | _j ".$2 // empty"; }

# Is $1 a source-code path (as opposed to docs/config)?
mk_is_code() {
  printf '%s' "$1" | grep -qiE '\.(cs|ts|tsx|js|jsx|mjs|cjs|vue|dart|py|go|rs|sql|kt|swift|rb|php|razor|cshtml|sh|ps1)$'
}

# Does the repo at $MK_CWD have a test runner we could expect to run?
mk_has_tests() {
  local root; root=$(git -C "$MK_CWD" rev-parse --show-toplevel 2>/dev/null) || return 1
  [ -f "$root/package.json" ] && grep -qE '"test"[[:space:]]*:' "$root/package.json" && return 0
  find "$root" -maxdepth 4 -name '*.csproj' 2>/dev/null | grep -qiE 'test' && return 0
  [ -f "$root/pubspec.yaml" ] && [ -d "$root/test" ] && return 0
  [ -f "$root/Cargo.toml" ] && return 0
  [ -f "$root/go.mod" ] && find "$root" -maxdepth 4 -name '*_test.go' 2>/dev/null | grep -q . && return 0
  { [ -f "$root/pytest.ini" ] || grep -qs pytest "$root/pyproject.toml"; } && return 0
  return 1
}
