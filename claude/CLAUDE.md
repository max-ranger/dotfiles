# Claude — Global Instructions

## Workflow

- **Pull requests:** always create PRs via the `pr-draft` skill (any "create/open a PR",
  `/pr`, `/pr-draft`). Never hand-roll `gh pr create` — `pr-draft` is authoritative.
- **Commits:** hooks (`commit-hygiene`, `secure-commits`, `pre-commit-checks`) gate every
  commit — a hook `ask` is a stop sign, not a speed bump. Skill-produced artifacts
  (e.g. `docs/superpowers/**`) never get committed; their content belongs in basic-memory.
- **Unattended loops:** before a long self-correcting run (agentic loop, `/loop`, fan-out),
  state a machine-checkable success signal and a bound.
  Reference: `~/.claude/docs/loop-engineering.md`.

## Knowledge Memory (basic-memory)

Durable, non-code project knowledge lives in **basic-memory** (rendered as an Obsidian
knowledge graph; gives Claude cross-session context).

- **Project mapping:** in a git repo, the basic-memory project = the git-root folder name
  (the SessionStart hook surfaces it). Missing project, or a non-repo/cowork session:
  ask which project to use or whether to create one — never auto-create.
- **Session start:** before substantive work, call `recent_activity` and read the project's
  `Overview` note. Skip for trivial/throwaway tasks.
- **What to capture:** tech stack and significant technical / architectural / design /
  product / ops decisions. No work logs, no play-by-play.
- **Skill artifacts are scratch:** specs, plans, and ADR/design files written by skills are
  working copies — distill their durable decisions into basic-memory instead of committing
  them; writing such a file does not count as capturing.
- **Writing is confirm-first:** at checkpoints (task done, pre-commit, session wind-down)
  present draft notes — title, folder, key observations + relations — and get approval
  before `write_note` / `edit_note`.
- **Note format:** structure and markup spec live in
  `~/.claude/docs/basic-memory-markup.md` — read it when writing notes.
