---
name: intent
description: Start a feature-sized change by capturing intent. Interviews the user one question at a time (hypothesis + confidence, guess attached) and writes docs/specs/<feature>/intent.md with Problem, Proposed outcome, Affected users & systems, Constraints, Open questions. Use for "/intent", "new feature", "let's plan X", "I want to build", or before any change bigger than half a day.
---

# Intent

Capture *why* before *what*. Output is `docs/specs/<feature>/intent.md`; nothing else is written.

## Process

1. Read `docs/overview.md` and `docs/architecture.md` if they exist. Skip the interview for anything you can answer from the repo.
2. Hypothesize the intent with a confidence number ("I think you want X, ~70%").
3. Ask **one** question at a time, each with your best guess attached, so a "yes" is enough. Stop asking at ~95% confidence or when the user says "go". Method: `${CLAUDE_PLUGIN_ROOT}/references/interview-method.md`.
4. Listen for "want vs. should want": name the difference once, let the user decide.
5. Write the file, restate the intent in the user's own words, and **stop the turn** so they can accept it. Status stays `draft` until they say so.

## File

`docs/specs/<feature>/intent.md` — `<feature>` is a short slug, no date, no number.

```markdown
# Intent: <title>

Status: draft | ready
Author: <user>

## Problem
<what hurts today, for whom, evidence>

## Proposed outcome
<what is true when this is done; observable, not implementation>

## Affected users & systems
<who notices; which repos, modules, data, integrations>

## Constraints
<non-negotiables: security, data, compatibility, deadline, budget>

## Open questions
- [ ] <question> — owner, needed by
```

Fixes, chores and small changes do not get an intent file; say so and proceed without one.
