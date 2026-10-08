# 0001. Record architecture decisions as ADRs in this repo

Date: YYYY-MM-DD
Status: accepted

## Context
Decisions a future reader would question (technology, boundaries, trade-offs) get lost in chat
and in people's heads. The repo is the one place every session, human or AI, local or remote,
can read.

## Decision
Record each such decision as `docs/decisions/NNNN-slug.md` (MADR-lite: context, decision,
consequences, alternatives). Accepted ADRs are immutable; a change of mind is a new ADR that
supersedes the old one.

## Consequences
- Decisions are reviewable in PRs and visible in `git log`.
- Writing one costs a few minutes; skipping it costs the reasoning.

## Alternatives considered
- External notes / wiki — invisible to remote sessions, drifts from the code.
