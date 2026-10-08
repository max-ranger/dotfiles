---
name: adr
description: Record an architecture or product decision as docs/decisions/NNNN-slug.md (MADR-lite). Use for "/adr", "record this decision", "write an ADR", or whenever a choice is made that a future reader would question (technology, boundary, trade-off, reversal of an earlier decision).
---

# ADR

One decision, one file, immutable once accepted. A changed mind gets a new ADR that supersedes the old one.

## Process

1. Find the next number: highest `NNNN` in `docs/decisions/` + 1 (start at `0001`). Slug from the title, no date in the filename.
2. Write the file from the template below. Context and consequences matter more than the decision line; a reader must be able to disagree with reasons.
3. If this supersedes an earlier ADR, set that ADR's status to `superseded by NNNN` (that status line is the only edit an accepted ADR ever gets).
4. Link it from `docs/overview.md` only if it changes how the project is described there.

## File

```markdown
# NNNN. <Title, as a decision: "Use X for Y">

Date: YYYY-MM-DD
Status: proposed | accepted | superseded by NNNN

## Context
<the forces: what problem, what constraints, what was tried or considered>

## Decision
<one or two sentences, active voice>

## Consequences
- <what becomes easier>
- <what becomes harder or is given up>
- <follow-ups this creates>

## Alternatives considered
- <option> — why not
```
