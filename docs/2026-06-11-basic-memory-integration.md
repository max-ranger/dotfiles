# basic-memory Integration — Design Spec

- **Date:** 2026-06-11
- **Status:** Approved (brainstorm) → ready for implementation plan
- **Owner:** Max Ranger

## Goal

Integrate basic-memory into the Claude Code workflow so that durable, non-code
project knowledge — tech stack, and technical/architectural/design decisions — is
captured in a **structured, per-repo knowledge base** that is:

1. browsable by the user as an **Obsidian knowledge graph**, and
2. usable by Claude as **cross-session context**.

## Decisions (from brainstorm)

| Question | Decision |
|---|---|
| Scope | **Coding-first, expandable** — scoped to git repos now; protocol designed to extend to non-coding "cowork" sessions later. |
| Capture mode | **Auto-capture, confirm-first** — collect continuously, draft at checkpoints, user approves before any write. |
| Repo → project mapping | **One project per repo** = git-root folder basename (`git rev-parse --show-toplevel`); created only after user confirmation. |
| Mechanism | **Hybrid, both now** — global `~/.claude/CLAUDE.md` (protocol) + thin `SessionStart` hook (activation). |
| Design/UX notes | **Separate `design/` folder.** |
| Work logs | **Durable knowledge only** — no per-session work-log notes. |
| New-project creation | **Confirm first** — never auto-create. |
| This spec's location | **Committed to the dotfiles repo** (`docs/`). |

## Architecture

Two version-controlled pieces, deployed like the rest of the dotfiles:

1. **`dotfiles/claude/CLAUDE.md`** → symlinked to `~/.claude/CLAUDE.md`.
   Holds the full **memory protocol**. Loaded in every session, so it already
   covers the future non-coding expansion without a hook.

2. **`dotfiles/claude/hooks/basic-memory-context.sh`** → registered in
   `claude/settings.json` under `SessionStart`, alongside the existing
   `push-notify-reminder.sh`. Thin activation that makes the protocol *fire*
   instead of relying on Claude's diligence.

The CLAUDE.md owns **what/how** (conventions); the hook owns **when** (activation).

## Repo → project resolution

- `REPO_ROOT = git -C "$CWD" rev-parse --show-toplevel`.
- `PROJECT = basename "$REPO_ROOT"` (e.g. `manticore`, `rentsales`, `dotfiles`).
- Existence is checked against `~/.basic-memory/config.json` → `projects.<name>`.
- If missing, Claude **asks the user** before creating it (never silent).
- Not in a git repo → no project resolution (non-coding/cowork path; CLAUDE.md
  guidance only, no hook output).

## Knowledge structure (per-repo project)

The graph must be **connected** — decisions link to hub notes, not orphaned.

```
<project>/
  Overview.md          # hub: what this repo is; links out to everything
  Tech Stack.md        # the stack as tagged observations
  decisions/           # one ADR-style note per significant decision
    YYYY-MM-DD-<slug>.md
  design/              # design/UX decisions & conventions (tokens, design system)
    <slug>.md
  architecture/        # component/system notes, created as they emerge
    <Component>.md
```

### Semantic markup (drives the Obsidian graph)

- **Observations:** `- [category] content #tag` — categorized, tagged facts.
  Starter categories: `framework`, `language`, `library`, `infra`, `tool`,
  `convention`, `constraint`, `rationale`, `risk`.
- **Relations:** `- relation_type [[Note]]` — starter vocabulary:
  `part_of`, `affects`, `depends_on`, `supersedes`, `motivated_by`.
  Every decision/design/architecture note links `part_of [[Overview]]`.
- **Decision tags** (map the named decision kinds): `#technical`,
  `#architectural`, `#design`, `#product`, `#ops`.

### Example decision note

```markdown
---
title: Adopt pnpm over npm
type: decision
tags: [technical, tooling]
---
## Context
Monorepo installs were slow and disk-heavy on CI.

## Decision
Standardize on pnpm + workspaces.

## Observations
- [rationale] Content-addressed store cuts install time ~40% #performance
- [constraint] Requires pnpm ≥ 9 in CI images #ops

## Relations
- part_of [[Overview]]
- affects [[Tech Stack]]
- supersedes [[2025-11-02-npm-workspaces]]
```

## Behavior (read / capture / write)

- **Session start (read):** hook surfaces `<project>` + existence + a one-line
  nudge. Claude then pulls `recent_activity` and reads `Overview` before
  substantive work. Trivial/throwaway tasks: skip.
- **During work (capture):** Claude silently collects durable facts only — new
  stack elements, decisions with rationale, architectural/design choices. No
  play-by-play.
- **Checkpoint (confirm → write):** at task completion / before a commit /
  session wind-down, Claude presents draft note(s) — title, folder, key
  observations + relations — the user approves or edits, then Claude calls
  `write_note` / `edit_note`. **Nothing is written without approval.**

## The SessionStart hook (`basic-memory-context.sh`)

Deliberately thin and fast:

1. `REPO_ROOT=$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null)`; if empty,
   exit 0 (no output).
2. `PROJECT=$(basename "$REPO_ROOT")`.
3. Parse `~/.basic-memory/config.json` for `projects.<PROJECT>`.
4. Emit one `SessionStart` `additionalContext` line, e.g.:
   - exists: *"📓 basic-memory project `manticore` — load recent notes before
     substantive work; capture decisions at checkpoints (confirm first)."*
   - missing: *"📓 No basic-memory project for `manticore` yet — offer to create
     one before capturing knowledge."*
5. Does **not** fetch recent activity itself (keeps it fast); Claude fetches via
   MCP once nudged.

## Global CLAUDE.md protocol (content outline)

A "Knowledge Memory (basic-memory)" section covering:

- Repo → project resolution rule and confirm-before-create.
- Read-at-start (`recent_activity` + `Overview`), skip for trivial tasks.
- Capture **durable knowledge only** (stack, decisions, architecture, design);
  no work logs.
- Structure (Overview / Tech Stack / decisions / design / architecture) and the
  observation/relation/tag conventions above.
- Write at checkpoints, **confirm-first**.
- A stub note for the future non-coding/cowork expansion (to be defined later).

## Deployment & reconciliation

- Add `claude/CLAUDE.md` to dotfiles; symlink `~/.claude/CLAUDE.md` (README
  bootstrap + Layout section, macOS and Windows variants).
- Add `claude/hooks/basic-memory-context.sh`; register it in
  `claude/settings.json` `SessionStart`.
- Trim the per-project template (`claude/templates/CLAUDE.md`) "Project Memory
  (basic-memory)" section to a short pointer to the global protocol, so the two
  don't diverge.

## Scope / non-goals

- **In scope:** coding sessions in git repos; per-repo knowledge capture.
- **Out of scope (now):** non-coding/cowork capture (designed-for, not built);
  basic-memory cloud sync changes; auto-creating projects; session/work logs;
  automatic (non-confirmed) writes.

## Success criteria

- New repo: Claude resolves the project name, offers to create it, and on
  approval seeds `Overview` + `Tech Stack`.
- Decisions during work surface as confirm-first draft notes at checkpoints and,
  once approved, appear as connected nodes in the Obsidian graph (tags + links).
- Reopening a repo later: Claude loads recent notes at session start and uses
  them as context.
- Everything lives in `~/BasicMemory/<project>/` as markdown the Obsidian vault
  renders.
