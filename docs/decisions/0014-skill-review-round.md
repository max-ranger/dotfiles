# 0014. Skill Review Round

Date: 2026-08-31
Status: accepted; the web interface guidelines are a path rule since 0003

Outcome of a verification review of six candidate skills/tools: icm-architect, Taste skill,
Vercel Web Interface Guidelines, Awesome Design MD, image-to-code, Playwright CLI. All six
security-swept clean (no scripts-with-network, no injection patterns); verdicts driven by
overlap with the installed design trio and by maintenance-vs-value.

## Key points

- **tool:** icm-architect (RinDig) skipped — method legit (real arXiv paper 2603.16021, markdown-only skill) but a hand-maintained code map stales with churn; value only on big undocumented legacy codebases, which none of the current repos are; revisit if one lands
- **tool:** Taste skill (Leonxlnx/taste-skill, ~82k stars) skipped — it IS `design-taste-frontend` v2 under the same install name, already pruned 2026-08-04; now ~35k tokens of prescriptive bans (em-dash, Inter, hex palettes, eyebrow quotas) that duplicate/contradict frontend-design + impeccable + emil-design-eng; its ~120-line "AI tells" catalog is a one-time read, not an install
- **decision:** Vercel Web Interface Guidelines adopted 2026-08-31 — vendored as `claude/skills/web-interface-guidelines/SKILL.md`, pruned of Vercel brand-voice copy rules, pinned to commit e3d624b (2026-08-17); ~45% of its ~120 mechanical browser/form/perf rules were not covered by the design trio; never use the official `npx skills` install (WebFetches unpinned live rules every run)
- **tool:** Awesome Design MD (VoltAgent, ~111k stars) pointer only — grounded scraped-CSS brand DESIGN.md files, not slop (the knockoff repos are); no local copy: cherry-pick 2–3 files into a project the day it needs an aesthetic anchor; reference use only — trade-dress means never ship a brand clone, and named fonts (Söhne, Circular) are unlicensed
- **tool:** image-to-code skipped — the viral 82k-star one is Codex image-generation-first (premise absent in Claude Code); the screenshot-compare-iterate loop is native (Browser pane + impeccable); if a strict 1:1 pixel-replication job ever lands, borrow a Pillow pixel-diff script (yuzhworkhard-wq/image-to-code has one) instead of installing a skill
- **decision:** Playwright CLI (@playwright/cli) installed globally 2026-08-31 (v0.1.18) — Microsoft's agent CLI, ~4x cheaper in tokens than playwright-mcp, emits live-verified `getByRole` specs; global binary + per-repo test adoption when a repo commits to an e2e suite (Cerberus and Manticore lined up); Browser pane stays the interactive verifier; playwright-mcp not used
- **constraint:** Playwright cannot drive Flutter — Pegasus e2e needs Flutter `integration_test` or Patrol (own review when Pegasus gets there); even Flutter web renders to canvas, so DOM/role locators don't apply
- **constraint:** when installing the playwright-cli skill into a repo: edit down its `allowed-tools` (frontmatter pre-approves ALL `npx`/`npm` invocations) and gitignore `.playwright-cli/` + `state-save` outputs (cookies/session state on disk)
- **rationale:** pattern across all six: skills earn a keep only as mechanical checkable rules, concrete reference data, or real tooling — judgment/taste skills are redundant with Claude 5-class models; same reasoning as the 2026-08-04 consolidation

## Related

- relates to [0011. Plugin skill hook curation](0011-plugin-skill-hook-curation.md)
- relates to [0013. Claude Code Tooling Decisions](0013-claude-code-tooling-decisions.md)
