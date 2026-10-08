#!/bin/bash
# PreToolUse (Write|Edit|MultiEdit): once per session, before the FIRST edit of a UI
# file, deny and make the model decide whether a design skill should run first.
# After a design skill ran (track-skills.sh) or after the one nudge, UI edits pass.
INPUT=$(cat)
source "$(dirname "$0")/_markers.sh"
mk_init "$INPUT"
[ -n "$MK_DIR" ] || exit 0
FILE=$(printf '%s' "$INPUT" | _j '.tool_input.file_path // empty')
[ -z "$FILE" ] && exit 0

is_ui=false
printf '%s' "$FILE" | grep -qiE '\.(vue|tsx|jsx|css|scss|html|razor|cshtml)$' && is_ui=true
printf '%s' "$FILE" | grep -qiE '/lib/.*(widget|screen|page|view|ui|component|presentation)[^/]*\.dart$' && is_ui=true
$is_ui || exit 0

[ "$(mk_field design session)" = "$MK_SESSION" ] && exit 0
NUDGE="$MK_DIR/design-nudged-$MK_SESSION"
[ -f "$NUDGE" ] && exit 0
touch "$NUDGE"

jq -nc --arg f "$(basename "$FILE")" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",
  permissionDecisionReason:("Design check (once per session): " + $f + " is a UI file. If this change touches layout, spacing, color, motion, states or component UX, run the emil-design-eng skill (interaction polish) or impeccable (audit/refine) FIRST and let it shape the change, then redo the edit. If it is only logic, wiring or copy, redo the edit as is; this check will not fire again this session.")}}'
exit 0
