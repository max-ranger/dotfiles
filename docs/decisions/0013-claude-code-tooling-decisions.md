# 0013. Claude Code Tooling Decisions

Date: 2026-08-24
Status: accepted; the memory-queue parts are superseded by 0002

Outcome of a fair-validation review of four candidate plugins (claude-mem, Headroom,
claude-code-setup, Task Observer) plus a rework of in-session feedback capture.

## Key points

- **tool:** claude-mem skipped — episodic logging is redundant with existing docs/git history; avoids a third session-start context injector; its MCP search is cross-project by design, a leakage risk for client repos
- **tool:** Headroom skipped — compresses tool output, not user input as marketed; the only independent benchmark showed no net cost savings on Claude Code because compression invalidates prompt-cache prefixes
- **tool:** claude-code-setup retained — run one-shot when onboarding a repo; verified read-only (suggestions only, never installs anything)
- **tool:** Task Observer skipped — covered by periodic /insights runs plus the new memory-queue mechanism
- **constraint:** basic-memory is exclusively local; the claude.ai Basic Memory Cloud connector was removed from the account 2026-08-24
- **convention:** in-session feedback capture: durable decisions/corrections are appended immediately to `~/.claude/memory-queue/<git-root slug>.md`; the `memory-queue-gate` Stop hook blocks session end until the queue is flushed into basic-memory (confirm-first) or discarded
- **rationale:** claude.ai General-tab account preferences do not reach Claude Code sessions — tone/behavior rules must live in `~/.claude/CLAUDE.md`
