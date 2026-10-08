# Project docs and the SDLC artifacts

Knowledge lives in git, next to the code it describes. One rule: *describes one repo → that repo's `docs/`; spans repos or has no repo → the `handbook` repo.* No external memory tool.

```
docs/
  overview.md            hub: what, for whom, state of play, where things are
  architecture.md        the non-obvious structure (entry points, boundaries, data flow)
  decisions/NNNN-slug.md ADRs, numbered, immutable once accepted (supersede, don't edit)
  specs/<feature>/       intent.md → spec.md → plan.md   (slug names, no dates)
  plans/                 plan-mode output (`plansDirectory`); the accepted plan is copied to specs/<feature>/plan.md
  review.md              the review policy /code-review and the verifier follow
```

Scale by change size:
- **Fix / chore / tiny change**: no artifacts. Commit message + PR carry the record.
- **Feature-sized change** (more than ~half a day or touches a boundary): `/intent` → `/spec` → plan mode → build → verify → `/pr`. The spec is approved before code; if the implementation departs from the plan, the plan is updated in the same commit.
- **A decision that would surprise a future reader** (technology, boundary, trade-off): `/adr`.

Topical docs sit next to these when a repo needs them: `tech-stack.md`, `product-brief.md`, `design/`, `architecture/<component>.md`, `runbooks/`.

Data that must not enter git (tester data, customer documents, database dumps) lives in `~/Code/assets/test-data/<project>/` or `~/Code/backups/`, with a README that says why. A repo's own privacy rule beats this layout: a note that would break it stays outside git.

What never becomes a file: tickets, timelines, handoffs, session logs. `git log`, PRs and issues are that record. Hubs describe what is true now; history lives in git.

Cowork writes only under `docs/` (intent, spec, decisions); Claude Code implements. The handoff between them is the spec file, not a kickoff prompt.
