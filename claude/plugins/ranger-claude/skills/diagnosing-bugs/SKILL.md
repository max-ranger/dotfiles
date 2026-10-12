---
name: diagnosing-bugs
description: Use when something is broken, throwing, failing, flaky or slow and the cause is not obvious after one look — "debug this", "why does this fail", a stack trace, a regression, a performance drop.
---

# Diagnosing bugs

The skill is the feedback loop. Everything after it is mechanical.

## 1. Build a red-capable loop first

Name **one command** you have already run that goes red on this exact bug and will go green when it is fixed: a failing test at the nearest seam, a curl against the dev server, a CLI call with a fixture, a headless browser script, a replayed captured request, a throwaway harness, a bisection script, a differential run of old vs new. The loop must be:

- red-capable: it asserts the user's exact symptom, not "did not crash"
- deterministic (flaky bugs: loop the trigger until the reproduction rate is high enough to debug)
- fast: seconds
- runnable by you unattended

No red command, no hypothesis. Reading code to build a theory before this command exists is the failure this skill prevents. If you genuinely cannot build one, say so, list what you tried, and ask for the environment or a redacted artifact (HAR, log, recording).

## 2. Reproduce and minimise

Run it red. Confirm it is the user's bug, not a neighbour. Then cut inputs, callers, config and steps one at a time until every remaining element is load-bearing. The minimal repro is the regression test later.

## 3. Hypothesise, ranked, falsifiable

Three to five hypotheses before testing any. Each states its prediction: "if X is the cause, changing Y makes it disappear". Show the ranked list to Max before probing; he often re-ranks it instantly.

## 4. Instrument one variable at a time

Debugger or REPL over logs. Targeted logs only where they separate hypotheses, every one tagged `[DEBUG-xxxx]` so cleanup is one grep. Never "log everything and grep". Performance: measure a baseline first, then bisect.

## 5. Fix at the root, test first

Regression test before the fix, at a seam that exercises the real bug pattern. Watch it fail, fix, watch it pass, rerun the original loop. If no correct seam exists, that is a finding: record it. **Three failed fixes means stop**: question the architecture or the premise and ask, do not stack a fourth.

## 6. Cleanup before "done"

Original loop green. Regression test in. `grep DEBUG-` finds nothing. Throwaway harnesses deleted. The hypothesis that was right is in the commit message. Secrets in any pasted output are `<REDACTED>`.
