#!/bin/bash
# Stop: block the first two stops of a session when source code was edited and no test
# run is recorded after the last edit. Auto mode continues on the reason, runs the
# tests, fixes, and stops again. Bounded: two blocks per session, then it lets go.
INPUT=$(cat)
source "$(dirname "$0")/_markers.sh"
mk_init "$INPUT"
[ -n "$MK_DIR" ] || exit 0

EDIT_SESSION=$(mk_field last-edit session)
[ "$EDIT_SESSION" = "$MK_SESSION" ] || exit 0          # no code edits in this session
mk_has_tests || exit 0                                   # nothing to run here

EDIT_TS=$(mk_field last-edit ts); EDIT_FILE=$(mk_field last-edit file)
TEST_SESSION=$(mk_field tests session); TEST_TS=$(mk_field tests ts)
ATT="$MK_DIR/verify-attempts-$MK_SESSION"
if [ "$TEST_SESSION" = "$MK_SESSION" ] && [ "${TEST_TS:-0}" -ge "${EDIT_TS:-0}" ]; then
  rm -f "$ATT"                                           # tests ran after the edit: reset the budget
  exit 0
fi

COUNT=$(cat "$ATT" 2>/dev/null || echo 0)
[ "$COUNT" -ge 2 ] && exit 0
echo $((COUNT + 1)) > "$ATT"

jq -nc --arg f "$(basename "$EDIT_FILE")" --arg n "$((COUNT + 1))" \
  '{decision:"block",reason:("Verify gate (" + $n + "/2): source code was edited this session (last: " + $f + ") and no test run is recorded after that edit. Run the project test command now (plus build/lint where they exist), fix what fails, state the result with the real output in your final message, then stop. If the change is genuinely untestable here, say so explicitly and stop.")}'
exit 0
