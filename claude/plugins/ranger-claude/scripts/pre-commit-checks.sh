#!/bin/bash
# Runs eslint + tests before `git commit` (PreToolUse Bash).
# Tools must already be installed in the project — missing tools are reported
# but never block. Failures block the commit so they get fixed first.

source "$(dirname "$0")/_parse-input.sh"
source "$(dirname "$0")/_git-cmd.sh"
[ -z "$HOOK_COMMAND" ] && exit 0

# Every `git … commit` in the command, with the repo it targets (git -C <repo>, cd <repo> &&).
gc_parse "$HOOK_COMMAND" "$HOOK_CWD"
COMMITS=$(gc_find commit)
[ -z "$COMMITS" ] && exit 0

emit() {
  local decision="$1" reason="$2"
  reason=${reason//\\/\\\\}
  reason=${reason//\"/\\\"}
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"%s"}}\n' "$decision" "$reason"
  # exit 0 so the deny + the lint/test output (the reason) actually reach Claude.
  # exit 2 discards the JSON and reads empty stderr — the commit gets blocked with
  # no visible reason, so the failure can't be fixed. (Matches security-gate.sh.)
  exit 0
}

# Lint and tests run only for a commit in the session's own repo: for one in another
# repo (git -C, cd) this hook would run that repo's code before the command is approved.
SESSION_ROOT=$(git -C "$HOOK_CWD" rev-parse --show-toplevel 2>/dev/null)
FAILURES=""
CHECKED=""
check_repo() {
  local i="$1" ROOT STAGED_DART STAGED_JS ESLINT_BIN PKG_JSON TEST_RUNNER
  local ANALYZE_OUTPUT ANALYZE_STATUS DART_TEST_OUTPUT DART_TEST_STATUS LINT_OUTPUT LINT_STATUS TEST_OUTPUT TEST_STATUS
  ROOT=$(gc_git "$i" rev-parse --show-toplevel 2>/dev/null)
  [ -z "$ROOT" ] && return
  if [ "$ROOT" != "$SESSION_ROOT" ]; then
    echo "[pre-commit-checks] $ROOT is not this session's repo: lint/tests skipped there" >&2
    return
  fi
  [ -n "$CHECKED" ] && return                          # one run per command
  CHECKED=1

  # --- Flutter / Dart (pubspec.yaml projects) ---
  if [ -f "$ROOT/pubspec.yaml" ]; then
    STAGED_DART=$(gc_git "$i" diff --cached --name-only --diff-filter=ACMR 2>/dev/null \
      | grep -E '\.dart$' || true)

    if [ -n "$STAGED_DART" ]; then
      if command -v flutter >/dev/null 2>&1; then
        ANALYZE_OUTPUT=$(cd "$ROOT" && flutter analyze --no-pub 2>&1)
        ANALYZE_STATUS=$?
        if [ "$ANALYZE_STATUS" -ne 0 ]; then
          FAILURES="${FAILURES}flutter analyze failed:\n$(printf '%s' "$ANALYZE_OUTPUT" | tail -40)\n\n"
        fi

        DART_TEST_OUTPUT=$(cd "$ROOT" && flutter test 2>&1)
        DART_TEST_STATUS=$?
        if [ "$DART_TEST_STATUS" -ne 0 ]; then
          FAILURES="${FAILURES}flutter tests failed:\n$(printf '%s' "$DART_TEST_OUTPUT" | tail -40)\n\n"
        fi
      else
        echo "[pre-commit-checks] flutter not on PATH — skipping Dart checks" >&2
      fi
    fi
  fi

  [ -f "$ROOT/package.json" ] || return

  STAGED_JS=$(gc_git "$i" diff --cached --name-only --diff-filter=ACMR 2>/dev/null \
    | grep -E '\.(js|jsx|ts|tsx|vue|mjs|cjs)$' || true)

  if [ -n "$STAGED_JS" ]; then
    ESLINT_BIN=""
    [ -f "$ROOT/node_modules/.bin/eslint" ] && ESLINT_BIN="$ROOT/node_modules/.bin/eslint"
    [ -z "$ESLINT_BIN" ] && [ -f "$ROOT/node_modules/.bin/eslint.cmd" ] && ESLINT_BIN="$ROOT/node_modules/.bin/eslint.cmd"

    if [ -n "$ESLINT_BIN" ]; then
      LINT_OUTPUT=$(cd "$ROOT" && echo "$STAGED_JS" | xargs "$ESLINT_BIN" --max-warnings=0 2>&1)
      LINT_STATUS=$?
      if [ "$LINT_STATUS" -ne 0 ]; then
        FAILURES="${FAILURES}eslint failed:\n$(printf '%s' "$LINT_OUTPUT" | tail -40)\n\n"
      fi
    fi
  fi

  PKG_JSON="$ROOT/package.json"
  if grep -qE '"test"[[:space:]]*:' "$PKG_JSON" 2>/dev/null; then
    TEST_RUNNER=""
    if [ -f "$ROOT/pnpm-lock.yaml" ] && command -v pnpm >/dev/null 2>&1; then
      TEST_RUNNER="pnpm test"
    elif [ -f "$ROOT/yarn.lock" ] && command -v yarn >/dev/null 2>&1; then
      TEST_RUNNER="yarn test"
    elif command -v npm >/dev/null 2>&1; then
      TEST_RUNNER="npm test --silent"
    fi

    if [ -n "$TEST_RUNNER" ]; then
      TEST_OUTPUT=$(cd "$ROOT" && eval "$TEST_RUNNER" 2>&1)
      TEST_STATUS=$?
      if [ "$TEST_STATUS" -ne 0 ]; then
        FAILURES="${FAILURES}tests failed:\n$(printf '%s' "$TEST_OUTPUT" | tail -40)\n"
      fi
    fi
  fi
}

for i in $COMMITS; do check_repo "$i"; done

if [ -n "$FAILURES" ]; then
  emit deny "PreCommit: $(printf '%b' "$FAILURES")"
fi

exit 0
