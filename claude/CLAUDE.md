# Claude — Global Instructions

## Knowledge Memory (basic-memory)

Durable, non-code project knowledge lives in **basic-memory**, structured so it
renders as an Obsidian knowledge graph and gives Claude cross-session context.

**Project mapping (coding sessions):**
- In a git repo, the basic-memory project = the git-root folder name
  (`git rev-parse --show-toplevel` basename), e.g. `manticore`, `rentsales`.
- If that project does not exist, **ask before creating it** (never auto-create).
- The SessionStart hook surfaces the resolved project name and whether it exists.

**At session start (read):** before substantive work, call `recent_activity` and
read the project's `Overview` note. Skip for trivial/throwaway tasks.

**What to capture (durable only):** tech stack, and technical / architectural /
design / product / ops **decisions**. No work logs, no play-by-play.

**Structure (per project):**
- `Overview` — hub note; what the repo is; links to everything.
- `Tech Stack` — stack as tagged observations.
- `decisions/YYYY-MM-DD-<slug>` — one ADR-style note per significant decision.
- `design/<slug>` — design/UX decisions & conventions.
- `architecture/<Component>` — component/system notes, as they emerge.

**Markup (drives the graph):**
- Observations: `- [category] content #tag`
  (categories: framework, language, library, infra, tool, convention,
  constraint, rationale, risk).
- Relations: `- relation_type [[Note]]`
  (vocabulary: part_of, affects, depends_on, supersedes, motivated_by).
  Every decision/design/architecture note links `part_of [[Overview]]`.
- Decision tags: #technical #architectural #design #product #ops.

**Writing (confirm-first):** capture during work; at checkpoints (task done,
before a commit, session wind-down) present the draft note(s) — title, folder,
key observations + relations — get approval, then `write_note` / `edit_note`.
Nothing is written without approval.

**Skill-produced artifacts (specs, plans, design docs):** Skills that emit
knowledge as files — e.g. superpowers `brainstorming` (`docs/superpowers/specs/`)
and `writing-plans` (`docs/superpowers/plans/`), or any ADR / design / product
`.md` a skill writes — are **working artifacts, not the system of record.**
Writing such a file does **not** satisfy this protocol: distill the durable
decisions within it into basic-memory (`decisions/` `design/` `architecture/`),
confirm-first. Where a skill says "user preference for location overrides the
default," that preference **is basic-memory** — the repo path is a scratch copy.

**Non-coding / cowork sessions:** the same capture discipline applies; the target
project convention for non-repo work will be defined when that is enabled.
