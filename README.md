# dotfiles

A reference for setting up a new machine the way I like it — Claude Code configs, hooks,
custom skills, VS Code settings, package lists, and notes on what I actually use.

**This is documentation, not an auto-syncing setup.** Nothing here is symlinked or run
automatically. On a new machine you *copy* what you want into place. When you find a better
way to do something, update the live file and copy it back here by hand. The repo is the
canonical record of the preferred setup — kept current manually.

## Layout

```
claude/                 # mirrors ~/.claude/ — copy these into ~/.claude/
  CLAUDE.md             # Global user instructions (basic-memory protocol) → ~/.claude/CLAUDE.md
  settings.json         # Claude Code user settings (hooks, plugins, flags)  → ~/.claude/settings.json
  hooks/                # Shell + PowerShell hooks referenced by settings.json → ~/.claude/hooks/
  skills/               # User-level skills → ~/.claude/skills/
    pr-draft/               # own — draft PR generator
    emil-design-eng/        # vendored — emilkowalski/skill (motion/design eng)
    design-taste-frontend/  # vendored — bnd-1/taste-skill (anti-generic UI)
  repo-template/        # NOT part of ~/.claude — seed for a new project's .claude/
    CLAUDE.md           # Per-project working-principles base → a project's .claude/CLAUDE.md
git/
  gitignore             # Generic all-purpose .gitignore to drop into new project repos
brew/
  Brewfile              # Homebrew packages, casks, VS Code ext. (regenerate with `brew bundle dump`)
scripts/
  install-dotnet.sh     # Install .NET SDK (latest LTS) — .NET isn't in Homebrew
vscode/
  settings.json         # VS Code user settings → ~/Library/Application Support/Code/User/
  keybindings.json      # VS Code user keybindings (extensions tracked in brew/Brewfile)
```

> Two distinct `CLAUDE.md` files, separated by destination: `claude/CLAUDE.md` is the **global**
> one — it seeds `~/.claude/CLAUDE.md` (cross-project behavior — knowledge graph / basic-memory
> flows). `claude/repo-template/CLAUDE.md` is the **repo** one — it seeds a project's
> `.claude/CLAUDE.md` (per-project working principles). Both load and compose: Claude Code reads
> the global file *and* the repo file. Don't restate the global rules in a repo file — only add
> or override project-specifics.

## Bootstrap a new machine

Everything below is a **copy** — no symlinks. Re-run any line to refresh from the repo.

### macOS / Linux

```bash
git clone git@github.com-ranger:max-ranger/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Claude config — copy into ~/.claude/ (real files, not links)
mkdir -p ~/.claude/skills
cp    claude/CLAUDE.md                    ~/.claude/CLAUDE.md
cp    claude/settings.json                ~/.claude/settings.json
cp -R claude/hooks                        ~/.claude/hooks
cp -R claude/skills/pr-draft              ~/.claude/skills/pr-draft
cp -R claude/skills/emil-design-eng       ~/.claude/skills/emil-design-eng
cp -R claude/skills/design-taste-frontend ~/.claude/skills/design-taste-frontend

# VS Code user config (extensions install via the Brewfile)
VSC="$HOME/Library/Application Support/Code/User"
mkdir -p "$VSC"
cp vscode/settings.json    "$VSC/settings.json"
cp vscode/keybindings.json "$VSC/keybindings.json"

# Homebrew packages (installs casks + VS Code extensions too)
brew bundle --file=brew/Brewfile

# .NET SDK — not managed by Homebrew; installs via Microsoft's official
# installer (latest LTS). Idempotent: skips if .NET is already present.
./scripts/install-dotnet.sh
```

### Windows

```powershell
git clone git@github.com-ranger:max-ranger/dotfiles.git C:\Dev\ranger\dotfiles
cd C:\Dev\ranger\dotfiles

# Claude config — copy into %USERPROFILE%\.claude\
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\skills" | Out-Null
Copy-Item        claude\CLAUDE.md                    "$env:USERPROFILE\.claude\CLAUDE.md"
Copy-Item        claude\settings.json                "$env:USERPROFILE\.claude\settings.json"
Copy-Item -Recurse claude\hooks                      "$env:USERPROFILE\.claude\hooks"
Copy-Item -Recurse claude\skills\pr-draft            "$env:USERPROFILE\.claude\skills\pr-draft"
Copy-Item -Recurse claude\skills\emil-design-eng     "$env:USERPROFILE\.claude\skills\emil-design-eng"
Copy-Item -Recurse claude\skills\design-taste-frontend "$env:USERPROFILE\.claude\skills\design-taste-frontend"

# VS Code user config (extensions install separately)
Copy-Item vscode\settings.json    "$env:APPDATA\Code\User\settings.json"
Copy-Item vscode\keybindings.json "$env:APPDATA\Code\User\keybindings.json"
```

## Git commit signing & verification (SSH)

Commits are **SSH-signed** with the machine's one key (`~/.ssh/ssh-key`) — not GPG — so they
show **Verified** on GitHub. "One key to rule them all": the *same* key both authenticates
pushes and signs commits. Three steps, with two non-obvious gotchas that cause the dreaded
**Unverified** badge.

**1. Tell git to SSH-sign every commit** (global settings, machine-local — they live in
`~/.gitconfig`, which this repo does not track):

```bash
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/ssh-key
git config --global commit.gpgsign true
```

**2. Register the key on GitHub _twice_ — Gotcha #1.** GitHub treats *Authentication* and
*Signing* keys as separate entries even for identical key bytes. Adding the key for push/pull
does **not** make signatures verify. Add the same `~/.ssh/ssh-key.pub` a second time at
**Settings → SSH and GPG keys → New SSH key → Key type: _Signing Key_**. Also make sure the
commit email is a **verified** email on the account (**Gotcha #2** — otherwise GitHub reports
`unverified_email` instead of `valid`). GitHub verifies signatures *dynamically*, so getting
this right flips already-pushed commits to Verified too — no re-commit needed.

**3. Let git verify signatures locally.** Without this, `git log --show-signature` errors with
`gpg.ssh.allowedSignersFile needs to be configured`. Build the allowed-signers file from your
own key (principal = your commit email) and point git at it:

```bash
mkdir -p ~/.config/git
echo "$(git config user.email) $(cat ~/.ssh/ssh-key.pub)" >> ~/.config/git/allowed_signers
git config --global gpg.ssh.allowedSignersFile ~/.config/git/allowed_signers
# verify — should print: Good "git" signature for <email>
git log --show-signature -1
```

> **Windows:** same three steps with `%USERPROFILE%\.ssh\ssh-key` and
> `%USERPROFILE%\.config\git\allowed_signers`. Git for Windows may ship its own `ssh-keygen`
> that can't sign — if signing fails, point git at OpenSSH's:
> `git config --global gpg.ssh.program "C:/Windows/System32/OpenSSH/ssh-keygen.exe"`.

> **No keys or signer files are tracked in this repo — by design.** `~/.ssh/*` and
> `~/.config/git/allowed_signers` are machine-local identity/secrets; the commands above
> regenerate the signer file from whatever key the new machine already holds. This section is
> the record of *how*, not the material itself.

## Starting a new project

Seed the project's Claude memory from the **repo** template — it lives in `.claude/`
(`.claude/CLAUDE.md` auto-loads exactly like a root `CLAUDE.md`, and composes with your
global `~/.claude/CLAUDE.md`) — then tailor it to the project:

```bash
mkdir -p .claude
cp ~/dotfiles/claude/repo-template/CLAUDE.md ./.claude/CLAUDE.md    # Windows: copy from C:\Dev\ranger\dotfiles\
cp ~/dotfiles/git/gitignore ./.gitignore                           # generic all-purpose ignore for the stack
```

The repo template is a living base — if you discover an improvement worth keeping across all
projects, port it back into `claude/repo-template/CLAUDE.md` here.

## Keeping it current (by hand)

Nothing is symlinked, so the live files and this repo **do not sync automatically** — that's
the point. When you improve a hook, skill, setting, or template:

1. Make the change in the live location (or here in the repo).
2. Copy it the other way so both match — re-run the relevant `cp` line above, or copy the
   edited live file back into the repo.
3. Commit and push from this repo.

To refresh the Brewfile from your current Mac (package descriptions are included by default):

```bash
brew bundle dump --file=brew/Brewfile --force
git commit -am "brew: refresh package list"
```

VS Code extensions are tracked inline in `brew/Brewfile` (the `vscode "..."` lines) and refresh
with the `brew bundle dump` above.

## Third-party skills & plugins

**Vendored skills** (copied into `claude/skills/`, pinned — refresh by re-downloading `SKILL.md`):
- `emil-design-eng` — [emilkowalski/skill](https://github.com/emilkowalski/skill)
- `design-taste-frontend` — [bnd-1/taste-skill](https://github.com/bnd-1/taste-skill)

**Plugins** (declared in `settings.json` → `enabledPlugins` + `extraKnownMarketplaces`, installed by Claude Code on startup):
- `andrej-karpathy-skills@karpathy-skills` — [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)
- `ui-ux-pro-max@ui-ux-pro-max-skill` — [nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill)
- `impeccable@impeccable` — [pbakaus/impeccable](https://github.com/pbakaus/impeccable)

## What's intentionally NOT here

- `~/.claude/projects/` — per-project memory and history, machine-local
- `~/.claude/plugins/` — managed by Claude Code's plugin system, restored via `enabledPlugins` in `settings.json`
- `~/.claude/cache/`, `~/.claude/telemetry/`, session state — ephemeral
- `~/.ssh/` keys and `~/.config/git/allowed_signers` — machine-local SSH identity/signer list; see *Git commit signing & verification* to recreate the signer file
- Anything matching `.gitignore` (env files, credentials, local overrides)
