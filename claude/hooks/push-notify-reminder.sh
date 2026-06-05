#!/bin/bash
# SessionStart hook: reminds the model to push-notify the user at hand-off
# points. Backs up the feedback_push_notify_on_idle.md memory entry with a
# stronger in-context signal. See ~/.claude/projects/C--Dev-ranger/memory/
# feedback_push_notify_on_idle.md for the full rule.

cat <<'EOF'
{"continue":true,"suppressOutput":true,"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"Push-notify default behavior (user-wide): call the PushNotification tool at hand-off points — when you finish a task, ask a clarifying question, request permission, or hit a blocker needing a decision. Lead with what the user would act on, keep it under 200 chars. The user works in Warp on Windows and frequently uses the Claude iOS app's Remote Control to step away — without a push they have no signal that work has stalled. If the harness reports the push was suppressed (user active or no Remote Control), that's expected — no action needed. Skip for routine mid-turn progress or replies seconds after the user typed."}}
EOF
