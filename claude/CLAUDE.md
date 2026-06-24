# Claude — Global Instructions

## Harness & Workflow Rules

Hooks enforce these where possible; honor them even where they cannot.

**Commit hygiene.** Stage explicitly — check `git status` first; never blanket
`git add -A` / `git add .` without knowing what it sweeps in. Never commit OS/editor
junk (`.DS_Store`, `*.log`, swap/backup files), scratch/temp files, build or dependency
output, or skill-produced artifacts under `docs/superpowers/`. The `commit-hygiene` hook
will `ask` before such a commit — treat that prompt as a stop sign, not a speed bump.

**Pull requests.** ALWAYS create PRs through the `pr-draft` skill (trigger it on "create
a PR", "open a PR", "/pr", "/pr-draft", etc.). Do not hand-roll `gh pr create`, and do not
use other PR skills (e.g. `commit-push-pr`) for PR creation — `pr-draft` is authoritative.

**Skill artifacts → basic-memory.** Files written by skills (brainstorming specs,
writing-plans plans, ADR/design `.md`) are scratch copies, not the system of record.
Distill the durable decisions into basic-memory (confirm-first); do not commit the scratch
artifacts. Details in Knowledge Memory below.

**Hooks are hard gates.** A hook `deny` is final. A hook `ask` means stop and get a real
decision — never reword or re-chain a command to slip past a gate.

**Loop discipline.** Before any iterative/agentic loop, state a machine-checkable success
signal (tests / types / build / lint) and a bound (max iterations or token budget). No
signal, no loop. Reference: `~/.claude/docs/loop-engineering.md`.

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

**Skill-produced artifacts (specs, plans, design docs):** Skills and design
plugins that emit knowledge as files — e.g. superpowers `brainstorming`
(`docs/superpowers/specs/`) and `writing-plans` (`docs/superpowers/plans/`),
design skills, or any ADR / design / product `.md` a skill writes — are
**working artifacts, not the system of record.** Their durable content **always
lands in basic-memory, never in the repo as the source of truth.**
Writing such a file does **not** satisfy this protocol: distill the durable
decisions within it into basic-memory (`decisions/` `design/` `architecture/`),
confirm-first. Where a skill says "user preference for location overrides the
default," that preference **is basic-memory** — the repo path is a scratch copy.

**Non-repo / cowork sessions (no git root):** there is no automatic project
mapping. Before capturing — and before any plugin/skill writes durable output
(design skills, superpowers, etc.) — resolve a target basic-memory project: if an
existing project clearly fits the work, use it; otherwise **ask which project to
use, or whether to create a new one — confirm first, never auto-create.** Once
resolved, the same capture discipline applies. Plugin/skill output lands in that
basic-memory project, not in stray files in the working directory.
