# Loop Engineering with Claude — A Working Guide

*Saved for reference. The short version: never run a loop without a signal the model can check by itself.*

## What loop engineering is

Designing the work so Claude runs in a **closed loop**: act → observe a
machine-checkable signal → correct → repeat, until a defined success condition
is green. The opposite is open-loop "one-shot prompting," where the model emits
an answer and *you* eyeball it. Loops win because the model's own mistakes get
caught by the environment, not by you.

## The one rule that matters

**No loop without a signal the model can read on its own.** Tests, type-check,
build exit code, lint, a diff, an HTTP 200, a screenshot comparison — something
objective. No signal → it isn't a loop, it's vibes with extra steps.

## The three loops you actually use

1. **Inner loop (the craft loop)** — inside a single task.
   TDD is the canonical form: failing test (red) → make it pass (green) →
   refactor. The superpowers `test-driven-development`, `systematic-debugging`,
   and `verification-before-completion` skills *are* this loop, packaged. Use
   them. Tighten it with small diffs, run the signal after every change, and
   never claim "done" without showing the green output.

2. **Recurring / self-paced loop (`/loop`)** — run a prompt or slash command on
   an interval, or let the model self-pace until a condition holds. Good for
   babysitting CI, polling a deploy, "keep fixing lint until clean," watch tasks.
   - `/loop 5m /check-deploy` — every 5 minutes.
   - `/loop <task>` (no interval) — model self-paces via wake-ups.
   - **Always give it an exit condition**, or it runs forever.

3. **Fan-out loop (Workflow / parallel agents)** — decompose into N independent
   subtasks, run concurrently, verify each, synthesize. For audits, migrations,
   multi-file reviews. The superpowers `dispatching-parallel-agents` skill and
   the Workflow tool cover this. Note: Workflow can spawn many agents and spend a
   lot of tokens — it's opt-in, so ask for it explicitly ("use a workflow").

## Setting up a good loop (checklist)

- [ ] **Define "done"** as a command that exits 0/1 (or a number to hit). Say it out loud.
- [ ] **Make the signal honest** — tests must actually run (not skip), build must really fail on error.
- [ ] **Bound it** — max iterations, a token budget, or a clear exit condition. Unbounded loops burn money.
- [ ] **Gate the side effects** — hooks block the irreversible steps so the loop can run hot without risk.
- [ ] **Keep diffs small** — one logical change per iteration, so a red signal points at one cause.
- [ ] **Verify before claiming** — paste the green output; never assert success from memory.

## How to drive me in a loop (your side)

- Give me the **success command** up front: *"done = `pnpm test && pnpm typecheck` both green."*
- Prefer **"iterate until X"** over "do X" when X is checkable — it licenses me to self-correct instead of stopping at the first attempt.
- State the **budget**: *"spend up to ~200k tokens / 20 iterations, then report."*
- For background/recurring work, say **"use /loop"** + interval + exit condition.
- For big parallel work, say **"fan this out"** / **"use a workflow."**

## Anti-patterns

- Open-loop on unverifiable goals ("make it nicer") — define a proxy signal or it never converges.
- Looping against a broken or skipped test suite — you're amplifying a lie.
- Unbounded `/loop` with no exit condition.
- Letting the loop commit/push freely — that's what the commit hooks are for.

## The connection to your harness

A loop is only as safe as its guardrails. The hooks (deterministic gates) are
what let a loop run unattended: they block bad commits, dangerous commands, and
secret leaks regardless of what the model "decides." Loop engineering and harness
engineering are the same project from two ends — the harness makes autonomy safe;
the loop makes safety productive.
