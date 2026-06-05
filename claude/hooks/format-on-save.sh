#!/bin/bash
# Auto-formats files after Claude edits them (PostToolUse Edit|Write).
# Reports when the project is missing prettier instead of failing silently.

source ~/.claude/hooks/_parse-input.sh
[ -z "$HOOK_FILE_PATH" ] || [ ! -f "$HOOK_FILE_PATH" ] && exit 0

EXTENSION="${HOOK_FILE_PATH##*.}"

case "$EXTENSION" in
  rs) command -v rustfmt >/dev/null 2>&1 && rustfmt "$HOOK_FILE_PATH" 2>/dev/null || true; exit 0 ;;
  go) command -v gofmt >/dev/null 2>&1 && gofmt -w "$HOOK_FILE_PATH" 2>/dev/null || true; exit 0 ;;
esac

case "$EXTENSION" in
  js|jsx|ts|tsx|vue|json|jsonc|css|scss|md|yaml|yml|html) ;;
  *) exit 0 ;;
esac

find_project_root() {
  local dir="$1"
  while [ "$dir" != "/" ] && [ "$dir" != "." ] && [ -n "$dir" ]; do
    if [ -f "$dir/package.json" ]; then echo "$dir"; return; fi
    dir=$(dirname "$dir")
  done
}

ROOT=$(find_project_root "$(dirname "$HOOK_FILE_PATH")")
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
