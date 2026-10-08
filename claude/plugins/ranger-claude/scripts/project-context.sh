#!/bin/bash
# SessionStart: point the session at the repo's own docs (the solo-dev SDLC layout)
# and at the handbook repo for cross-repo knowledge.
INPUT=$(cat)
source "$(dirname "$0")/_markers.sh"
mk_init "$INPUT"

ROOT=$(git -C "$MK_CWD" rev-parse --show-toplevel 2>/dev/null)
[ -z "$ROOT" ] && ROOT="$MK_CWD"
MSG=""

if [ -f "$ROOT/docs/overview.md" ]; then
  MSG="📁 Project docs live in the repo: read docs/overview.md first. Specs: docs/specs/<feature>/{intent,spec,plan}.md · Decisions (ADRs): docs/decisions/ · Review policy: docs/review.md · Plans from plan mode: docs/plans/. Feature-sized work starts with /intent and /spec; fixes and chores need no artifacts."
else
  MSG="📁 This repo has no docs/ yet. Before the first feature-sized change, scaffold it from dotfiles/claude/repo-template/docs (overview, architecture, decisions, specs, review policy). Decisions and specs belong in the repo, not outside it."
fi

HANDBOOK="$HOME/Code/handbook"
[ -f "$HANDBOOK/docs/overview.md" ] && [ "$ROOT" != "$HANDBOOK" ] && MSG="$MSG Cross-repo and non-code knowledge: $HANDBOOK/docs/overview.md (handbook repo)."


jq -nc --arg m "$MSG" '{continue:true,suppressOutput:true,hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$m}}'
