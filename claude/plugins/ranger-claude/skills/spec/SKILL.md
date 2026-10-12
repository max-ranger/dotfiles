---
name: spec
description: Use when an intent is accepted and the feature needs its contract before any code — "/spec", "write the spec", "spec this out", "what exactly are we building" — or when a plan or PR has no spec to be checked against.
---

# Spec

The spec is the contract that the plan, the build, the verifier and `/code-review` are checked against. It is approved by the user before code exists. Reference skeleton: `${CLAUDE_PLUGIN_ROOT}/references/spec-template.md`.

## Process

1. Read `docs/specs/<feature>/intent.md` (required), `docs/overview.md`, `docs/architecture.md`, relevant ADRs in `docs/decisions/`, and the code the change touches. Trace the real flow; do not spec from assumptions.
2. Apply the simplicity ladder: every requirement that can be met by existing code, the framework or a native feature says so.
3. Write `spec.md`. Requirements are numbered and testable ("R3: a member without consent cannot be enrolled; API returns 409"). No file paths and no code snippets: they go stale within days. The one exception is a snippet that encodes a decision more precisely than prose can (a schema, a state machine, a type shape), inlined at that decision.
   Acceptance names the seam each requirement is proven at: the highest existing seam that reaches the behavior, ideally one for the whole feature; a new seam is proposed, not assumed.
4. List **areas of concern** honestly: what could go wrong, what you are unsure about, what needs a decision (`/adr`).
5. Run one `grill` round on the spec before asking for approval: premise, every hard-to-reverse choice (stack, data model, hosting, identity, public contracts) with its door and blast radius, and what would make this a failure even if it technically works. Facts are looked up, only decisions are asked. If the design is large, a fresh-context builder check (`${CLAUDE_PLUGIN_ROOT}/references/interview-method.md`, "Builder check") lists what a builder would still have to guess.
6. Present the spec in chat as a short summary (requirements + concerns + the grill questions), then **stop the turn**. No plan, no code until the user approves. If they approve, set `Status: approved` and tell them the next step is plan mode.

## File

```markdown
# Spec: <title>

Status: draft | approved
Intent: ./intent.md

## Requirements
- R1 …
- R2 …

## Design
<approach, boundaries touched, data changes, API/UX surface; diagrams only if they show a mechanism>

## Constraint mapping
| Constraint (from intent) | How the design satisfies it |
|---|---|

## Out of scope
<explicitly not now>

## Areas of concern
- <risk or unknown> — proposed handling

## Open questions
- [ ] <question> — blocking? yes/no

## Acceptance
<how the verifier proves each R: test, command, screenshot>
```

Keep the spec alive: when the implementation departs from it, update the spec in the same commit.
