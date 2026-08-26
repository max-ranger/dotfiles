# basic-memory — note structure & markup

Reference for writing basic-memory notes — read before `write_note` / `edit_note` (or before
editing the markdown directly). The markup is what drives the Obsidian knowledge graph; the
structure is what keeps "what is true now" separable from "what we did when".

## Structure (per project)

One basic-memory project per **big project**, not per git repo — a product split across
several repos is one project. The folder tree mirrors the workspace on disk: cross-repo
material at the top level, everything repo-specific under a folder named exactly like the
repo. A single-repo project uses the same layout with the project level acting as the repo
level (no repo folders) — same hub, same `decisions/`, same per-ticket notes.

`<ID>` below is the work-item key from the project's tracker (`#123` on GitHub, `ABC-123`
on Jira or Azure DevOps, …). Projects without a tracker (e.g. personal projects) keep the
same `tickets/` notes and structure, just titled without a key (`Short Title.md`,
`Short Title Plan YYYY-MM-DD.md`) — the status/timeline/handoff discipline is what
carries, not the numbering.

```
<Project>/
  README.md              the convention as it applies to this project (short)
  Overview.md            project hub: what it is, repos, conventions, CURRENT STATE (dated),
                         ticket index, open items without a ticket, people
  Tech Stack.md          cross-repo stack facts, dated
  architecture/          durable cross-repo "how it works, as built" notes
  decisions/             YYYY-MM-DD Title.md — one ADR-style note per significant decision
  tickets/               cross-repo ticket masters  <ID> Title.md
                         + frozen artifacts        <ID> Plan YYYY-MM-DD.md (type: plan)
  <repo>/
    Overview.md          repo hub: composition, conventions, CURRENT STATE, tickets touching
                         this repo, open items
    Tech Stack.md
    architecture/        repo-level design notes, as built
    decisions/           YYYY-MM-DD Title.md
    tickets/             one note per ticket touching this repo   <ID> Title.md
```

`design/<slug>` (design/UX conventions) is still valid where a project has UI work.

## Which note gets what

| Information | Note | Rule |
| :--- | :--- | :--- |
| What is true *now* — state, open items, who reviews what | `Overview` hub (project or repo) | Rewrite in place; a stale line is a wrong line. Date the state section. |
| What we did, *when* — branches, PRs, commits, test counts, verification runs | ticket note **Timeline** | Append-only, one dated entry per working session; outcomes, not play-by-play. |
| Handoff — what is left, deliberately-not-done items, how to reproduce | ticket note **Handoff** | Never in a decision note. |
| *Why* it is the way it is | `decisions/` | Written once. Supersede with a banner + `superseded_by` on the old note and `supersedes` on the new — never rewrite history. |
| *How* it works, as built | `architecture/` | Rewritten to match the code; the story of getting there stays in the ticket. |
| Point-in-time plans, research dumps | `tickets/<ID> Plan <date>.md`, `type: plan` | Frozen; banner instead of edits. |

A ticket spanning several repos gets a **master note at project level** (scope split per repo,
cross-repo timeline, status per repo) plus **one slice note per repo**. A one-repo ticket gets
only the slice; the project hub's ticket index still lists it. A one-line slice is a row in the
master's per-repo table, not a note. Unknown state is written as "not recorded — confirm",
never assumed.

## Titles, links, frontmatter

- Wikilinks resolve by **title**, so titles are unique per project: project-level notes use the
  plain title (`Overview`, `Tech Stack`, `Audit Logging`); repo-level notes carry the repo as a
  suffix — `Overview (<repo>)`, `<ID> Short Title (<repo>)`; decisions are unique through
  their date prefix.
- Frontmatter: `title`, `type` (`note` | `decision` | `ticket` | `plan`), `permalink`
  (lower-case slug of the path).
- Hierarchy through `part_of`: repo-level notes → `[[Overview (<repo>)]]`; repo hubs and
  project-level notes → `[[Overview]]`.

## Markup

- **Observations:** `- [category] content #tag`
  Categories: framework, language, library, infra, tool, solution (stack notes);
  convention, constraint, rationale, risk, decision, design, technical, architectural,
  testing, ops, process (everything else); scope, status (ticket notes);
  fact, bug, smell, context, standard, open (analysis notes).
- **Relations:** `- relation_type [[Note]]`
  Vocabulary: part_of, affects, depends_on, motivated_by, supersedes, superseded_by, relates_to.
  Every note except the project hub links `part_of` its hub (see above).
- **Decision tags:** #technical #architectural #design #product #ops #compliance #security.

## Ticket note skeleton

```
---
title: <ID> Short Title (repo)          # no suffix at project level; no <ID> without a tracker
type: ticket
permalink: <project>/<repo>/tickets/<id>-short-title
---
# <ID> Short Title — repo
One paragraph: what and why; link to the master note if cross-repo.
## Status (YYYY-MM-DD)      branch / PR / reviewers / gates / blockers, one line each
## Scope in this repo       what changes here, and what deliberately does not
## Timeline                 - YYYY-MM-DD - outcome (commit, PR, decision, verification, numbers)
## Handoff                  recipes, deliberately-left-undone items, open threads
## Observations             - [scope] … #<ID>   - [status] … #<ID>
## Relations                - part_of [[Overview (repo)]]  - part_of [[master]]  - affects [[…]]
```

## Session discipline

- Start: project hub → repo hub → ticket note for the ticket at hand (`recent_activity` first).
  Plans and decision notes are reference, not instructions.
- End / checkpoint: append the ticket timeline, refresh its status and handoff, then fix every
  hub line the session made stale — repo hub first, project hub if the ticket index or state
  table changed. Confirm-first still applies to every write.
