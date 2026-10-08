# 0008. Claude Harness Enforcement

Date: 2026-06-24
Status: accepted; superseded in part by 0002 (knowledge in git) and 0005 (gates as hooks)

Harness-level enforcement rules and fixes applied to the global Claude Code config (`~/.claude`) on 2026-06-24, to make rule-following deterministic rather than dependent on model discipline. Motivated by recurring failures: PRs not using the custom skill, unwanted files committed, and skill artifacts landing in repos instead of basic-memory.

## Key points

- **convention:** Code-quality/style guidelines stay at repo level (`.claude/CLAUDE.md` per repo), NOT promoted to global CLAUDE.md; global holds harness/workflow rules only. Karpathy guidelines remain available as the `karpathy-guidelines` skill

- **convention:** PreToolUse hooks must emit ask/deny as JSON on stdout + `exit 0`; `exit 2` discards the JSON and reads empty stderr, silently swallowing the decision (confirmed via official docs)
- **convention:** PR creation routes exclusively through the `pr-draft` skill, now model-invocable after removing `disable-model-invocation: true`; authoritative over `commit-push-pr`
- **tool:** `commit-hygiene.sh` (new PreToolUse Bash hook) asks before committing junk or skill artifacts — `.DS_Store`, logs, swap/backup files, scratch, dep/build dirs, `docs/superpowers/*`
- **tool:** `secure-commits.sh` and `pre-commit-checks.sh` changed from `exit 2` to `exit 0` + JSON so their deny/ask actually reach Claude (this was the "secret guard sometimes doesn't protect" bug)
- **convention:** plugin/skill durable output lands in basic-memory, never the repo as system of record; non-repo sessions resolve a project first, or ask which project / whether to create one (confirm first)
- **rationale:** three enforcement tiers — hooks (deterministic) > CLAUDE.md (contextual) > skills (procedural); only hooks guarantee, so put a hook under any must-not-break rule
- **constraint:** `pre-commit-checks.sh` has a 180s timeout; a slower test suite can time out and let the commit through — known residual
- **tool:** loop-engineering guide written to `~/.claude/docs/loop-engineering.md`: closed-loop work needs a machine-checkable signal + a bound
