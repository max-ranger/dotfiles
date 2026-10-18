#!/bin/bash
# Auto-formats files after Claude edits them (PostToolUse Edit|Write).
# Reports when the project is missing prettier instead of failing silently.

source "$(dirname "$0")/_parse-input.sh"
[ -z "$HOOK_FILE_PATH" ] || [ ! -f "$HOOK_FILE_PATH" ] && exit 0

EXTENSION="${HOOK_FILE_PATH##*.}"

# find_up <dir> <file>: the nearest folder at or above <dir> that holds <file>.
find_up() {
  local dir="$1"
  while [ "$dir" != "/" ] && [ "$dir" != "." ] && [ -n "$dir" ]; do
    if [ -f "$dir/$2" ]; then echo "$dir"; return; fi
    dir=$(dirname "$dir")
  done
}

case "$EXTENSION" in
  rs) command -v rustfmt >/dev/null 2>&1 && rustfmt "$HOOK_FILE_PATH" 2>/dev/null || true; exit 0 ;;
  go) command -v gofmt >/dev/null 2>&1 && gofmt -w "$HOOK_FILE_PATH" 2>/dev/null || true; exit 0 ;;
  dart) command -v dart >/dev/null 2>&1 && dart format "$HOOK_FILE_PATH" >/dev/null 2>&1 || true; exit 0 ;;
  cs)
    # Whitespace only, in folder mode: no restore or build (~1 s), the rules come from the
    # .editorconfig, which is also the opt-in. Style and analyzer rules stay with the build
    # (EnforceCodeStyleInBuild). Backslashes: a Windows path, which dirname can't split.
    command -v dotnet >/dev/null 2>&1 || exit 0
    CS_FILE=${HOOK_FILE_PATH//\\//}
    CS_DIR=$(dirname "$CS_FILE")
    [ -n "$(find_up "$CS_DIR" .editorconfig)" ] || exit 0
    (cd "$CS_DIR" && dotnet format whitespace . --folder --include "$(basename "$CS_FILE")") >/dev/null 2>&1 || \
      echo "[format-on-save] dotnet format failed for $HOOK_FILE_PATH"
    exit 0 ;;
esac

case "$EXTENSION" in
  js|jsx|ts|tsx|vue|json|jsonc|css|scss|md|yaml|yml|html) ;;
  *) exit 0 ;;
esac

ROOT=$(find_up "$(dirname "$HOOK_FILE_PATH")" package.json)
[ -z "$ROOT" ] && exit 0

REL="${HOOK_FILE_PATH#$ROOT/}"

PRETTIER_BIN=""
[ -f "$ROOT/node_modules/.bin/prettier" ] && PRETTIER_BIN="$ROOT/node_modules/.bin/prettier"
[ -z "$PRETTIER_BIN" ] && [ -f "$ROOT/node_modules/.bin/prettier.cmd" ] && PRETTIER_BIN="$ROOT/node_modules/.bin/prettier.cmd"

if [ -z "$PRETTIER_BIN" ]; then
  echo "[format-on-save] prettier not installed in $ROOT — skipping format for $REL"
  exit 0
fi

HAS_CONFIG=false
for cfg in .prettierrc .prettierrc.json .prettierrc.yml .prettierrc.yaml .prettierrc.js .prettierrc.cjs .prettierrc.mjs .prettierrc.toml prettier.config.js prettier.config.cjs prettier.config.mjs; do
  [ -f "$ROOT/$cfg" ] && HAS_CONFIG=true && break
done
if [ "$HAS_CONFIG" = false ] && grep -q '"prettier"' "$ROOT/package.json" 2>/dev/null; then
  HAS_CONFIG=true
fi

if [ "$HAS_CONFIG" = false ]; then
  echo "[format-on-save] prettier installed but no config found in $ROOT — skipping format for $REL"
  exit 0
fi

(cd "$ROOT" && "$PRETTIER_BIN" --write --ignore-unknown "$HOOK_FILE_PATH") >/dev/null 2>&1 || \
  echo "[format-on-save] prettier failed for $REL"

exit 0
