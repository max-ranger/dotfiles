# dotfiles — overview

**What:** the canonical record of how Max's machines are set up: Homebrew/winget manifests, Git, .NET, VS Code, and the Claude Code tooling (the `ranger-claude` plugin, global rules, repo template).
**State:** tooling upgrade of 2026-10-08 landed: basic-memory retired, hooks moved into the plugin, rules replace stack snippets, SDLC skills added. Next: migrate legacy notes from `~/BasicMemory`, then the `~/Code` folder move.
**Stack:** bash hooks, markdown skills/rules, JSON manifests. No build.

## Where things are

- Decisions: [decisions/](decisions/)
- Plugin: `claude/plugins/ranger-claude/` (hooks in `scripts/`, skills, agent, vendored references)
- Global rules: `claude/rules/` → `~/.claude/rules/`
- Repo template for new projects: `claude/repo-template/` (CLAUDE.md, `.claude/settings.json`, `docs/` skeleton)
- Review policy: [review.md](review.md)

## Conventions worth knowing

- Copy-based: nothing is symlinked. The plugin is installed from the GitHub marketplace (`max-ranger/dotfiles`); on the dev machine from the local checkout (directory source). Either way it is a cached copy: bump the plugin `version` and run `claude plugin update ranger-claude@ranger` after changes.
- Hooks are tested with synthetic JSON input against a throwaway git repo (see `docs/review.md`).
