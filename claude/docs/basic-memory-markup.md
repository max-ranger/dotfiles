# basic-memory — note structure & markup

Reference for writing basic-memory notes — read before `write_note` / `edit_note`.
The markup is what drives the Obsidian knowledge graph.

## Structure (per project)

- `Overview` — hub note; what the repo is; links to everything.
- `Tech Stack` — stack as tagged observations.
- `decisions/YYYY-MM-DD-<slug>` — one ADR-style note per significant decision.
- `design/<slug>` — design/UX decisions & conventions.
- `architecture/<Component>` — component/system notes, as they emerge.

## Markup

- **Observations:** `- [category] content #tag`
  Categories: framework, language, library, infra, tool, convention, constraint,
  rationale, risk.
- **Relations:** `- relation_type [[Note]]`
  Vocabulary: part_of, affects, depends_on, supersedes, motivated_by.
  Every decisions/design/architecture note links `part_of [[Overview]]`.
- **Decision tags:** #technical #architectural #design #product #ops.
