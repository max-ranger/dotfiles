# dotfiles — overview

**What:** the canonical record of how Max's machines are set up: Homebrew and winget manifests, Git config and signing, the .NET install script, VS Code settings, the PowerShell profile. Copied into place by hand, nothing symlinked.
**State:** 2026-10-29: the Claude Code tooling (plugin, rules, templates, 17 ADRs) moved to the `kitsune` repo ([0024](decisions/0024-claude-tooling-moved-to-kitsune.md)). What remains is machine setup. Earlier: the workspace moved from `~/Dev` to a flat `~/Code` ([0015](decisions/0015-flat-code-workspace.md)).
**Stack:** Brewfile, JSON manifests, shell and PowerShell scripts. No build.

## Where things are

- Decisions: [decisions/](decisions/). Numbers missing here belong to the Claude tooling and live in kitsune.
- Claude Code tooling: `~/Code/kitsune` (plugin `ranger-claude@ranger`, global rules, repo template)
- Review policy: [review.md](review.md)

## Conventions worth knowing

- Copy-based: nothing is symlinked. Change the live file, copy it back here, commit.
- The Brewfile and `winget/packages.json` change together.
