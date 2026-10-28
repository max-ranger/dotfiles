# 0021. Third review round: Ponytail 5, text cherry-picked, nothing installed

Date: 2026-10-28
Status: accepted

## Context
[0003](0003-own-the-tooling-as-the-ranger-claude-plugin.md) took the ladder from ponytail v4.13 and skipped the plugin. The same day ponytail shipped version 5: rules rewritten around "the smallest complete change", a review and an audit skill, a codebase map at session start, a neutral `shortcut:` marker with a limit and an upgrade trigger (5.1), and a cost band with a board above the Claude Code prompt (5.3). Its published benchmark (39 tasks, 5 runs, Opus 5.5) shows the rewrite cheaper than v4.13 by a tenth and a blind judge preferring its replies, mainly because they end with what was skipped or not checked. Upstream read at v5.3.2 (`09c434a`).

## Decision
Nothing is installed. Six pieces of text are distilled, as plugin 2.1.0 and the global rules:

- `rules/simplicity.md`: the scope paragraph (every place the change must reach, and what it could break, is the scope), finish every part the scope names, a bug fix greps every caller and fixes the shared code once, moved code keeps its error handling and validation.
- The marker keeps its `ranger: shortcut` prefix and gains ponytail's two parts: the limit and when to upgrade. A marker without a trigger rots; the five markers in the plugin's scripts got theirs. `git grep` is the ledger, no debt skill.
- `rules/output.md`: finished work ends with what was skipped or not checked and the risk the reader must know.
- The repo template's `docs/review.md`: a load pass (judged against the load the repo declares, and the review says which it assumed) and a marked shortcut is a decision, not a finding. The verifier treats such a marker as a ruling already made.

Not taken:
- The codebase map (a regex index of exports injected at session start): each repo's `docs/architecture.md` is the map, and [0016](0016-second-review-cherry-pick-text-install-nothing.md) already declined session-start injection. Revisit if a large undocumented repo lands.
- The band and board: tooling, but it ships only inside the ponytail plugin, whose hooks would inject a second ruleset over ours. Claude Code's own cost view covers the need.
- Levels (lite, full, ultra): the global CLAUDE.md already challenges unnecessary work on every turn.
- The review and audit output format: `/code-review` reports findings through its own typed output, which already demands a concrete failure case per finding.

## Consequences
- Every ranger shortcut now names when to upgrade; a review can tell a decision from a finding.
- Existing product repos keep their older `docs/review.md`; the load pass reaches them when their policy is next touched.
- Door: two-way; cost if wrong: revert the plugin to 2.0.0 and the two rules.

## Alternatives considered
- Install ponytail beside the plugin: two rulesets for the same prompts, the objection of 0003.
- Port the codebase map to bash: a regex per language to maintain, for repos that already carry a written map.
