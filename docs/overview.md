# dotfiles — overview

**What:** the canonical record of how Max's machines are set up: Homebrew/winget manifests, Git, .NET, VS Code, and the Claude Code tooling (the `ranger-claude` plugin, global rules, repo template).
**State:** tooling upgrade of 2026-10-08 landed (basic-memory retired, hooks in the plugin, rules, SDLC skills). On 2026-10-08 the legacy notes were migrated into each repo's `docs/`, the `handbook` repo was created, and the workspace moved from `~/Dev` to a flat `~/Code` ([0015](decisions/0015-flat-code-workspace.md)). The nine pre-2026-10 decisions are ADRs 0006–0014. 2026-10-12: cherry-picks from superpowers and mattpocock/skills landed as plugin 1.1.0 (grill, diagnosing-bugs, testing rule, plan and verifier additions). 2026-10-13: every repo commits `.claude/settings.json`; plan drafts are gitignored scratch ([0016](decisions/0016-second-review-cherry-pick-text-install-nothing.md), [0017](decisions/0017-project-settings-committed-plan-drafts-scratch.md)). 2026-10-28: Ponytail 5 re-reviewed, text cherry-picked as plugin 2.1.0, nothing installed ([0021](decisions/0021-third-review-round-ponytail-5.md)).
**Stack:** bash hooks, markdown skills/rules, JSON manifests. No build.

## Where things are

- Decisions: [decisions/](decisions/)
- Plugin: `claude/plugins/ranger-claude/` (hooks in `scripts/`, skills, agent, vendored references)
- Global rules: `claude/rules/` → `~/.claude/rules/`
- Repo template for new projects: `claude/repo-template/` (`.claude/CLAUDE.md`, `.claude/settings.json`, `docs/` skeleton); the gitignore comes from `git/gitignore`
- Review policy: [review.md](review.md)

## Conventions worth knowing

- Copy-based: nothing is symlinked. The plugin is installed from the GitHub marketplace (`max-ranger/dotfiles`); on the dev machine from the local checkout (directory source). Either way it is a cached copy: bump the plugin `version` and run `claude plugin update ranger-claude@ranger` after changes.
- Hooks are tested with synthetic JSON input against a throwaway git repo (see `docs/review.md`).
