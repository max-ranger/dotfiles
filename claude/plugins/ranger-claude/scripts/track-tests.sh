#!/bin/bash
# PostToolUse (Bash): record test runs for the verify gate.
INPUT=$(cat)
source "$(dirname "$0")/_markers.sh"
mk_init "$INPUT"
[ -n "$MK_DIR" ] || exit 0

CMD=$(printf '%s' "$INPUT" | _j '.tool_input.command // empty')
[ -z "$CMD" ] && exit 0
if printf '%s' "$CMD" | grep -qE '(^|[;&| ])((pnpm|npm|yarn|bun)( [^;&|]*)? test|vitest|jest|dotnet test|flutter test|dart test|pytest|go test|cargo test|(npx )?playwright test|phpunit|rspec)(\b|$)'; then
  EXIT=$(printf '%s' "$INPUT" | _j '.tool_response.exit_code // .tool_response.exitCode // .tool_response.interrupted // empty')
  SAFE=$(printf '%s' "$CMD" | head -c 120 | jq -Rsr @json)
  mk_write tests "{\"command\":$SAFE,\"exit\":\"$EXIT\"}"
fi
exit 0
