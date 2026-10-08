# 0010. Lean CLAUDE.md layers for modern models

Date: 2026-08-04
Status: accepted; extended by 0003 (rules)

**Decision:** All Claude instruction layers (global `~/.claude/CLAUDE.md`, per-repo template)
are kept deliberately lean, written for Claude 5-class models (Fable/Opus 5). Instructions
that restate model or harness defaults are dropped; only non-derivable preferences stay.

## Key points

- **rationale:** Instruction files written to correct older models' failure modes (overcomplication, drive-by refactors, runaway loops) now cost standing tokens, dilute real priorities, or actively conflict with the modern harness
- **convention:** Global CLAUDE.md keeps only non-derivable preferences: pr-draft routing, hook-gate pointers, the basic-memory protocol — slimmed 4.8KB → 2.1KB
- **convention:** Reference material moves behind on-demand pointers in `~/.claude/docs/` (basic-memory-markup.md, loop-engineering.md) instead of loading every session
- **convention:** Repo template is a thin scaffold (project / commands / architecture / gotchas) plus opt-in per-stack snippets in `repo-template/stacks/` — a repo appends only the stacks it uses
- **convention:** Stack snippets keep only lint-invisible conventions; anything a linter/formatter enforces is not restated
- **convention:** Ask-before-acting bias replaced by "state assumptions, ask only decision-changing questions"
- **constraint:** The `Never add Co-Authored-By lines` rule is a hard personal rule — it was briefly dropped as a "harness conflict" and Max reinstated it with emphasis on 2026-08-05; it stays in the template and every deployed repo CLAUDE.md, and overrides the harness default
- **convention:** Prompt templates are opt-in paste rails (zero standing cost); the legacy 96%-confidence gate was replaced with decision-focused pre-planning questions
- **constraint:** Loop discipline (signal + bound) applies only to unattended/agentic loops, not to all iterative work

## Related

- affects [0006. Copy-based setup, no symlinks](0006-copy-based-setup-no-symlinks.md)
