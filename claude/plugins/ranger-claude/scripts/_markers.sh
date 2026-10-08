#!/bin/bash
# Shared helper for the gate hooks: per-repo marker files under .git/ranger/
# (never committed, per worktree). Each marker is a one-line JSON object.
#
#   source "$(dirname "$0")/_markers.sh"
#   HOOK_INPUT=$(cat); mk_init "$HOOK_INPUT"      # sets MK_DIR, MK_SESSION, MK_CWD, MK_HEAD
#   mk_write review '{"skill":"code-review"}'      # adds head/session/ts automatically
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
  MK_GITDIR=$(git -C "$MK_CWD" rev-parse --git-dir 2>/dev/null)
  MK_DIR=""
  if [ -n "$MK_GITDIR" ]; then
    case "$MK_GITDIR" in /*) ;; *) MK_GITDIR="$MK_CWD/$MK_GITDIR" ;; esac
    MK_DIR="$MK_GITDIR/ranger"
    mkdir -p "$MK_DIR" 2>/dev/null
  fi
  MK_HEAD=$(git -C "$MK_CWD" rev-parse HEAD 2>/dev/null || echo "none")
  export MK_SESSION MK_CWD MK_GITDIR MK_DIR MK_HEAD
}

mk_write() {
  local name="$1" extra="${2:-{\}}"
  [ -n "$MK_DIR" ] || return 0
  jq -nc --arg h "$MK_HEAD" --arg s "$MK_SESSION" --argjson ts "$(date +%s)" --argjson x "$extra" \
    '{head:$h,session:$s,ts:$ts} + $x' > "$MK_DIR/$name.json" 2>/dev/null
}

mk_read() { [ -n "$MK_DIR" ] && [ -f "$MK_DIR/$1.json" ] && cat "$MK_DIR/$1.json"; }
mk_field() { mk_read "$1" | _j ".$2 // empty"; }

# Is $1 a source-code path (as opposed to docs/config)?
mk_is_code() {
  printf '%s' "$1" | grep -qiE '\.(cs|ts|tsx|js|jsx|mjs|cjs|vue|dart|py|go|rs|sql|kt|swift|rb|php|razor|cshtml)$'
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
