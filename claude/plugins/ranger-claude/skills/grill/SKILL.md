---
name: grill
description: Stress-test a plan, stack choice, design or idea before it costs weeks — "grill this", "poke holes", "what am I missing", "challenge the premise", "is this a good idea", "sanity check", "what do you think of this plan", "before I commit to X". Not for a bug (diagnosing-bugs) or while writing a spec (spec runs one round itself).
---

# Grill

Attack the idea before the code exists. The failures that cost the most were never a bug: a wrong premise, a stack chosen for the wrong reason, a one-way door walked through casually. Your job here is to find those, not to be agreeable.

## How

Map the decisions as a tree: every decision branches into the ones that hang off it. Work it in **rounds**. The frontier is every decision whose prerequisites are settled. Ask the whole frontier in one round, numbered, each with your recommended answer, worded so that "yes" accepts the recommendation.

```
❓ Q1 — <title>: <the question; options if there are any>
➡️ <your recommendation, and the cost if it is wrong>
```

Order the round by damage: premise first ("does this need to exist, and is the problem what you think it is"), then anything hard to reverse (stack, data model, hosting, identity, public contracts), then scope, then detail. For each hard-to-reverse item say whether it is a one-way or two-way door and what the blast radius is.

Facts are your job, never Max's: look in the repo, the docs, the handbook, the web. Ask only for decisions. A question whose answer depends on another open question waits for the next round.

Also ask, once: what would make this a failure even if it technically works, and what would make you wince if it were built wrong.

## Done

The round is empty when nothing is silently assumed. End with two lists: **Rulings** (`decision — why — cost if wrong`) and **Still open**. Do not build or write the spec in the same turn; stop and let Max react.

Inside `/spec` this runs once, before approval is requested. Keep it to the decisions that would change the spec.
