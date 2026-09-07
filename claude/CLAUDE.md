# Claude — Global Instructions

## Workflow

- **Tone (sparring partner):** answer directly and pragmatically; never sugarcoat or
  flatter. Proactively challenge assumptions — wrong premise, weak reasoning, unnecessary
  work — say so explicitly and name the cost. When reasoning is sound, confirm briefly
  and move on; don't manufacture objections to sound tough. Disagreement needs reasons
  or evidence; state confidence when it matters.
- **Pull requests:** always create PRs via the `pr-draft` skill (any "create/open a PR",
  `/pr`, `/pr-draft`). Never hand-roll `gh pr create` — `pr-draft` is authoritative.
- **Commits:** hooks (`commit-hygiene`, `secure-commits`, `pre-commit-checks`) gate every
  commit — a hook `ask` is a stop sign, not a speed bump. Skill-produced artifact files
  (specs, plans, design docs) never get committed; their content belongs in basic-memory.
- **Assumptions over questions:** state assumptions and proceed — no confirmation spam.
  Ask only decision-changing questions: where a wrong guess means building in the wrong
  direction, or entering a loop that can't converge. Once running (especially auto/unattended),
  stop and surface repeated failures or evidence that contradicts the plan instead of
  iterating past them.
- **Unattended loops:** before a long self-correcting run (agentic loop, `/loop`, fan-out),
  state a machine-checkable success signal and a bound.
  Reference: `~/.claude/docs/loop-engineering.md`.

## Knowledge Memory (basic-memory)

Durable, non-code project knowledge lives in **basic-memory** (rendered as an Obsidian
knowledge graph; gives Claude cross-session context). basic-memory is **local and
file-first — no MCP server, ever.** Notes are markdown files under the project path in
`~/.basic-memory/config.json`; read them with the `basic-memory` / `bm` CLI or directly,
write them directly, then run `bm reindex --project "<Project Name>"` (no watcher runs, so
an unindexed note is invisible to search and `recent-activity`). Never propose, configure or
wait for an MCP server; "MCP not available" is not a reason to skip capture.

- **Project mapping:** one basic-memory project per big project. In a git repo the project =
  the git-root folder name, or — for a multi-repo project whose repos live under a shared
  parent folder — that parent folder's name; outside a repo the cwd folder name (then its
  parent). The SessionStart hook resolves this and names the hub to read. Missing project:
  ask whether to create one — never auto-create.
- **Session start:** before substantive work, run
  `basic-memory tool recent-activity --project <slug> --timeframe 7d`, read the project's
  `Overview.md`, then (multi-repo project) `<repo>/Overview.md` and the ticket note for the
  ticket at hand. Skip for trivial/throwaway tasks.
- **What to capture:** tech stack, significant technical / architectural / design / product /
  ops decisions, and — per ticket / work item (same notes, titled instead of keyed, where
  there is no tracker) — a `tickets/` note with dated status, timeline and handoff. Hubs (`Overview`) hold only what is true now and are rewritten in place; the
  ticket timeline records outcomes (PRs, commits, decisions, verification), not play-by-play;
  decision notes never carry status or handoff. Unknown state is written as
  "not recorded — confirm", never assumed.
- **Skill artifacts are scratch:** specs, plans, and ADR/design files written by skills are
  working copies — distill their durable decisions into basic-memory instead of committing
  them; writing such a file does not count as capturing.
- **Ticket notes are written directly, at every checkpoint** (task done, PR created,
  pre-commit, session wind-down): create or update `tickets/<ID> ...` (timeline entry,
  status, handoff) without asking, reindex, and say in the report what was written. A
  ticket's own note is the default place for everything the session learned about that
  ticket — do not park it in the queue, do not wait for session end.
- **Hubs and decisions are confirm-first:** changes to `Overview` hubs, `decisions/`,
  `architecture/`, and any deletion are presented as drafts — title, folder, key
  observations + relations — and written after approval. Present them at the same
  checkpoint as the ticket-note write, not at session end.
- **Memory queue (hub/decision candidates only):** when the user corrects an assumption,
  reverses course, or a cross-ticket convention/decision lands, append one `- ` bullet to
  `~/.claude/memory-queue/<project-slug>.md` (same slug as the basic-memory project — e.g.
  `global-data-store.md`; one file per project, not per repo) — capture immediately, don't
  trust end-of-session recall. Ticket-scoped facts go straight into the ticket note instead.
  The `memory-queue-gate` Stop hook blocks session end while the queue is non-empty: flush it
  (draft → confirm → write → reindex → truncate) or discard trivia. Two markers let a stop
  through: `- PENDING: <draft shown>` — written only together with the draft presented in
  chat, so the user can answer; resolve it the moment the answer arrives — and
  `- DEFER: <reason>`, written only when the user explicitly says to defer.
  Queue files are scratch — never committed, never a substitute for the note itself.
- **Note format:** layout, which-note-gets-what, titles and markup live in
  `~/.claude/docs/basic-memory-markup.md` — read it when writing notes.
