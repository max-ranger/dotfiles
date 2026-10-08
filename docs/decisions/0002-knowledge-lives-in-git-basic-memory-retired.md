# 0002. Project knowledge lives in git; basic-memory is retired

Date: 2026-10-08
Status: accepted

## Context
basic-memory was used as a local markdown vault with a prompt-enforced convention (hubs, tickets, decisions, observations, relations). Measured usage over four months: writes dominated; search 24 calls, graph traversal 6, while Claude read fixed files each session. Remote Claude Code sessions and Cowork cloud sessions cannot see a local vault at all. The three supporting hooks, ~35 lines of global CLAUDE.md, a memory queue with a Stop gate, and a stray `~/basic-memory` folder created by hooks without the env var were the running cost.

## Decision
One rule: *describes one repo → that repo's `docs/`; spans repos or has no repo → the `handbook` repo.* Poly-repo stays. Nothing else becomes a file: tickets, timelines and handoffs are `git log`, PRs and issues. basic-memory is uninstalled; `~/BasicMemory` is kept read-only until each project's notes are migrated or dropped.

## Consequences
- Remote sessions, Cowork and any future tool see the same docs as local sessions.
- Specs and plans ride in the same PR as the code; `/code-review` and the verifier can check against them.
- Cross-repo work moves from "tab into the other vault" to the handbook repo plus adding the other repo as a session directory.
- Docs-only commits appear in history; acceptable.
- Cowork projects point at the repo (or handbook) folder and write only under `docs/`.

## Alternatives considered
- graphify — a tree-sitter code index, not a decision memory; independent runs cost more for equal quality.
- Hybrid (bm project folder moved into the repo) — keeps machinery nobody uses.
- Clean split (architecture in repo, plans/tickets local) — keeps the least valuable half in the costliest place.
- A docs repo per code repo — splits history, spec cannot ride with the code.
