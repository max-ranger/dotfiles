#!/bin/bash
# format-on-save for C#: pipes a PostToolUse Edit JSON into the hook and checks the file.
# Needs bash + jq + the .NET SDK (skipped without it).
#   bash claude/plugins/ranger-claude/tests/format-on-save.test.sh
SCRIPTS="$(cd "$(dirname "$0")/../scripts" && pwd)"
command -v dotnet >/dev/null 2>&1 || { echo "dotnet not on PATH: skipped"; exit 0; }
T=$(mktemp -d "${TMPDIR:-/tmp}/ranger-format.XXXXXX")
trap 'rm -rf "$T"' EXIT
PASS=0; FAIL=0

MESSY=$'namespace X;\npublic class A {\n        public int B {get;set;}\n}\n'
# The .editorconfig sits two folders up (a space in the path), with a non-default indent.
mkdir -p "$T/with config/src/App" "$T/no config"
printf 'root = true\n[*.cs]\nindent_style = space\nindent_size = 2\n' > "$T/with config/.editorconfig"
printf '%s' "$MESSY" > "$T/with config/src/App/A.cs"
printf '%s' "$MESSY" > "$T/no config/A.cs"

edit() {
  jq -nc --arg f "$1" '{session_id:"test",hook_event_name:"PostToolUse",tool_name:"Edit",tool_input:{file_path:$f}}' \
    | bash "$SCRIPTS/format-on-save.sh"
}
check() {  # check <label> <file> <expected content>
  if [ "$(cat "$2")" = "$3" ]; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); printf 'FAIL  %s:\n%s\n' "$1" "$(cat "$2")"; fi
}

edit "$T/with config/src/App/A.cs"
check "formatted by the .editorconfig above it" "$T/with config/src/App/A.cs" $'namespace X;\n\npublic class A\n{\n  public int B { get; set; }\n}'
edit "$T/no config/A.cs"
check "left alone without an .editorconfig" "$T/no config/A.cs" "${MESSY%$'\n'}"

echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
