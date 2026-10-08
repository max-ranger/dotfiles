# 0011. Plugin skill hook curation

Date: 2026-08-04
Status: accepted; superseded in part by 0003 and 0005

**Decision:** Claude Code plugins, skills, and hooks are curated against a keep-test for the
Claude 5 era. A plugin/skill survives only if it provides (1) capability the model lacks,
(2) personal preference/taste, or (3) live context. Roster went 16 plugins → 7, hooks 10 → 7.

## Key points

- **convention:** Keep-test: capability the model lacks, personal preference/taste, or live context — instruction-shaped process enforcement fails the test
- **rationale:** Claude 5-class models (Fable/Opus 5) natively cover what reasoning-shaped plugins used to add: code review, simplification, feature pipelines, commit flows, behavioral guidelines
- **convention:** Deterministic hooks are explicitly kept — gates (security-gate, secure-commits, commit-hygiene, pre-commit-checks, format-on-save) don't obsolete with model capability; they're what makes auto-mode safe
- **rationale:** superpowers dropped: its ceremony (mandatory brainstorming, plan docs, skill-invocation preamble) fights the auto-mode workflow; planning arbitration is left to the model plus opt-in prompt templates
- **convention:** Instructional notification hooks retired in favor of native agentPushNotifEnabled / inputNeededNotifEnabled
- **convention:** Design skills consolidated one-per-role against the anti-AI-slop goal: frontend-design (direction, explicitly anti-AI-default), impeccable (refinement/audit vocabulary), emil-design-eng (interaction polish)
- **rationale:** ui-ux-pro-max dropped even for blank-page starts — deriving direction from the product's own subject beats picking from a stock catalog, which is templated by construction
- **constraint:** Re-enabling anything is one settings line; revisit-signals are documented (missed catalog on blank starts, debugging thrash → vendor systematic-debugging)
- **tool:** Surviving roster: frontend-design, claude-md-management, claude-code-setup, context7, typescript-lsp, impeccable, warp + vendored pr-draft, emil-design-eng

## Related

- affects [0010. Lean CLAUDE.md layers for modern models](0010-lean-claude-md-layers-for-modern-models.md)
