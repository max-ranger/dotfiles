#!/bin/bash
# Runs lint + tests before `git commit` (PreToolUse Bash): flutter, dotnet, eslint, npm.
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
  # The reason is tool output: its newlines, tabs and colour codes would make the JSON
  # invalid, and Claude Code then drops the deny and runs the commit.
  reason=$(printf '%s' "$reason" | sed $'s/\033\\[[0-9;]*[A-Za-z]//g' | tr -d '\000-\010\013\014\016-\037')
  reason=${reason//\\/\\\\}
  reason=${reason//\"/\\\"}
  reason=${reason//$'\n'/\\n}
  reason=${reason//$'\t'/\\t}
  reason=${reason//$'\r'/}
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"%s"}}\n' "$decision" "$reason"
  # exit 0 so the deny + the lint/test output (the reason) actually reach Claude.
  # exit 2 discards the JSON and reads empty stderr — the commit gets blocked with
  # no visible reason, so the failure can't be fixed. (Matches security-gate.sh.)
  exit 0
}

# dotnet_solution_dir <root> <root-relative path>: the folder of the nearest *.slnx / *.sln
# above the path, up to <root> (src/backend in the ranger-app template, backend/ in cerberus).
# ranger: shortcut — a project with no solution above it is not checked; every .NET repo
# here has one, and a lone .csproj would need its own test-project discovery.
dotnet_solution_dir() {
  local root="$1" dir f
  dir=$(dirname "$root/$2")
  while :; do
    for f in "$dir"/*.slnx "$dir"/*.sln; do
      [ -e "$f" ] && { printf '%s\n' "$dir"; return; }
    done
    [ "$dir" = "$root" ] || [ "$dir" = "/" ] && return
    dir=$(dirname "$dir")
  done
}

# Lint and tests run only for a commit in the session's own repo: for one in another
# repo (git -C, cd) this hook would run that repo's code before the command is approved.
SESSION_ROOT=$(git -C "$HOOK_CWD" rev-parse --show-toplevel 2>/dev/null)
# Real newlines, never `\n` + printf %b: %b would also expand the backslashes in the tool
# output (C:\Dev\…\tests turns into a tab, and a \c cuts the reason off).
NL=$'\n'
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
  local PENDING                                          # what an earlier `git add` / -a adds
  PENDING=$(gc_pending "$i" added)

  # --- Flutter / Dart (pubspec.yaml projects) ---
  if [ -f "$ROOT/pubspec.yaml" ]; then
    STAGED_DART=$( { gc_git "$i" diff --cached --name-only --diff-filter=ACMR 2>/dev/null; printf '%s\n' "$PENDING"; } \
      | grep -E '\.dart$' || true)

    if [ -n "$STAGED_DART" ]; then
      if command -v flutter >/dev/null 2>&1; then
        ANALYZE_OUTPUT=$(cd "$ROOT" && flutter analyze --no-pub 2>&1)
        ANALYZE_STATUS=$?
        if [ "$ANALYZE_STATUS" -ne 0 ]; then
          FAILURES="${FAILURES}flutter analyze failed:${NL}$(printf '%s' "$ANALYZE_OUTPUT" | tail -40)${NL}${NL}"
        fi

        DART_TEST_OUTPUT=$(cd "$ROOT" && flutter test 2>&1)
        DART_TEST_STATUS=$?
        if [ "$DART_TEST_STATUS" -ne 0 ]; then
          FAILURES="${FAILURES}flutter tests failed:${NL}$(printf '%s' "$DART_TEST_OUTPUT" | tail -40)${NL}${NL}"
        fi
      else
        echo "[pre-commit-checks] flutter not on PATH — skipping Dart checks" >&2
      fi
    fi
  fi

  # --- .NET: `dotnet test` (build + every test) in each solution a staged file belongs to ---
  # Deletions count: removing a type breaks the build as surely as editing one. So do the
  # files that steer the build: .editorconfig (EnforceCodeStyleInBuild), the SDK pin, feeds.
  local STAGED_DOTNET DOTNET_DIRS SLN_DIR SLN_COUNT SLN_FILE DOTNET_OUTPUT DOTNET_STATUS
  STAGED_DOTNET=$( { gc_git "$i" diff --cached --name-only --diff-filter=ACMRD 2>/dev/null; gc_pending "$i"; } \
    | grep -iE '\.(cs|csproj|props|targets|slnx|sln)$|(^|/)(\.editorconfig|global\.json|nuget\.config|packages\.lock\.json)$' \
    | sort -u || true)

  if [ -n "$STAGED_DOTNET" ]; then
    if command -v dotnet >/dev/null 2>&1; then
      DOTNET_DIRS=$(while IFS= read -r f; do dotnet_solution_dir "$ROOT" "$f"; done <<< "$STAGED_DOTNET" | sort -u)
      while IFS= read -r SLN_DIR; do
        [ -n "$SLN_DIR" ] || continue
        SLN_COUNT=0
        for SLN_FILE in "$SLN_DIR"/*.slnx "$SLN_DIR"/*.sln; do [ -e "$SLN_FILE" ] && SLN_COUNT=$((SLN_COUNT + 1)); done
        if [ "$SLN_COUNT" -gt 1 ]; then                # a bare `dotnet test` needs exactly one
          echo "[pre-commit-checks] several solutions in ${SLN_DIR#"$ROOT"/} — skipping dotnet test there" >&2
          continue
        fi
        # No extra flags: under Microsoft.Testing.Platform (global.json "test.runner") they reach
        # the test apps, which exit 5 on any they don't know (-nologo included). stdin is the
        # loop's list of folders: anything in the run that reads it would eat the rest.
        DOTNET_OUTPUT=$(cd "$SLN_DIR" && dotnet test 2>&1 </dev/null)
        DOTNET_STATUS=$?
        if [ "$DOTNET_STATUS" -ne 0 ]; then
          # Stack frames and build progress ("  Project -> path") would push the failing test
          # out of the last 40 lines.
          FAILURES="${FAILURES}dotnet test failed in ${SLN_DIR#"$ROOT"/}:${NL}$(printf '%s\n' "$DOTNET_OUTPUT" \
            | grep -vE '^[[:space:]]+at |^--- End of stack trace|^[[:space:]]*$|^[[:space:]]+[^[:space:]]+ -> |^Test run for |^A total of [0-9]+ test files' \
            | tail -40)${NL}${NL}"
        fi
      done <<< "$DOTNET_DIRS"
    else
      echo "[pre-commit-checks] dotnet not on PATH — skipping .NET checks" >&2
    fi
  fi

  [ -f "$ROOT/package.json" ] || return

  STAGED_JS=$( { gc_git "$i" diff --cached --name-only --diff-filter=ACMR 2>/dev/null; printf '%s\n' "$PENDING"; } \
    | grep -E '\.(js|jsx|ts|tsx|vue|mjs|cjs)$' | sort -u || true)

  if [ -n "$STAGED_JS" ]; then
    ESLINT_BIN=""
    [ -f "$ROOT/node_modules/.bin/eslint" ] && ESLINT_BIN="$ROOT/node_modules/.bin/eslint"
    [ -z "$ESLINT_BIN" ] && [ -f "$ROOT/node_modules/.bin/eslint.cmd" ] && ESLINT_BIN="$ROOT/node_modules/.bin/eslint.cmd"

    if [ -n "$ESLINT_BIN" ]; then
      LINT_OUTPUT=$(cd "$ROOT" && echo "$STAGED_JS" | xargs "$ESLINT_BIN" --max-warnings=0 2>&1)
      LINT_STATUS=$?
      if [ "$LINT_STATUS" -ne 0 ]; then
        FAILURES="${FAILURES}eslint failed:${NL}$(printf '%s' "$LINT_OUTPUT" | tail -40)${NL}${NL}"
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
        FAILURES="${FAILURES}tests failed:${NL}$(printf '%s' "$TEST_OUTPUT" | tail -40)${NL}"
      fi
    fi
  fi
}

for i in $COMMITS; do check_repo "$i"; done

if [ -n "$FAILURES" ]; then
  emit deny "PreCommit: $FAILURES"
fi

exit 0
