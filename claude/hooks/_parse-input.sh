#!/bin/bash
# Shared helper: reads stdin JSON, exports HOOK_* vars.
# Pure sed/bash extraction — no node/python dependency.
# Only fields actually consumed by other hooks are extracted:
#   tool_input.command, tool_input.file_path, message
# Values are JSON-decoded for the four common escapes (\" \\ \n \t \r).
# Multi-byte / \uXXXX sequences are passed through literally.

HOOK_INPUT=$(cat)
_oneline=$(printf '%s' "$HOOK_INPUT" | tr -d '\r' | tr '\n' ' ')

_json_extract() {
  local key="$1"
  printf '%s' "$_oneline" \
    | sed -nE "s/.*\"${key}\"[[:space:]]*:[[:space:]]*\"((\\\\.|[^\"\\\\])*)\".*/\\1/p"
}

_json_decode() {
  printf '%s' "$1" | sed -E 's/\\"/"/g; s/\\\\/\\/g; s/\\n/\n/g; s/\\t/\t/g; s/\\r/\r/g'
}

HOOK_COMMAND=$(_json_decode "$(_json_extract command)")
HOOK_FILE_PATH=$(_json_decode "$(_json_extract file_path)")
HOOK_MESSAGE=$(_json_decode "$(_json_extract message)")

export HOOK_COMMAND HOOK_FILE_PATH HOOK_MESSAGE
