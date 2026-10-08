# 0003. Own the Claude tooling as one plugin; vendor third-party text, reference third-party tools

Date: 2026-10-08
Status: accepted

## Context
The setup was an amalgam of own hooks in `~/.claude/hooks`, vendored skills, and third-party plugins. Measured skill usage across 28 stored sessions: `pr-draft` 21 invocations, every other skill 0, including the native `/code-review`, `/simplify`, `/security-review`. Candidates reviewed: ponytail (skip plugin, adopt ladder), graphify (no), addyosmani/agent-skills and superpowers (no backbone; 70% overlap with native features, zero C#/Flutter content), i-have-adhd (adopt rules, skip plugin).

## Decision
All instruction-shaped tooling is ours, in one plugin `ranger-claude` inside this repo, published through the repo's own marketplace (`.claude-plugin/marketplace.json`). Third-party content is vendored pinned with a source line (agent-skills references, Vercel web-interface rules, Emil Kowalski skill). Third-party plugins stay only where they are tools: context7, typescript-lsp, frontend-design, impeccable. Global rules (`~/.claude/rules/`) carry the output shape, the simplicity ladder, git rules, the docs layout, and path-scoped stack conventions; the global CLAUDE.md shrinks to workflow.

## Consequences
- One install (`ranger-claude@ranger`) brings hooks, skills and the verifier to any machine, cloud session or Cowork.
- Skills fire because hooks demand them (review gate, verify gate, design check), not because a description matched.
- Upstream improvements are cherry-picked deliberately, never auto-fetched.

## Alternatives considered
- agent-skills as the backbone — two routers for the same prompts, JS-only enforcement.
- Three plugins (hooks/skills/agents) — artificial split; a plugin bundles all three.
