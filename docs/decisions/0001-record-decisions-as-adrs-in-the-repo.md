# 0001. Record decisions as ADRs in the repo

Date: 2026-10-08
Status: accepted

## Context
Until now decisions lived in basic-memory notes under `~/BasicMemory/dotfiles/decisions/`. They were invisible to remote sessions and to anyone cloning the repo, and the tool's search and graph features went unused (24 searches and 6 graph traversals in four months across all projects).

## Decision
Decisions are `docs/decisions/NNNN-slug.md` files in this repo, MADR-lite, numbered, immutable once accepted. The nine legacy decision notes stay readable in `~/BasicMemory/dotfiles` until migrated or superseded.

## Consequences
- Decisions ride in PRs and `git log`.
- The memory-queue / confirm-first ritual disappears; a PR review replaces it.

## Alternatives considered
- Keep basic-memory as the index over repo docs — pointless once search and graph are unused.
