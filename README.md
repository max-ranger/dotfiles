# dotfiles

Personal machine setup — Claude Code configs, hooks, custom skills, and package lists. Shared across machines.

## Layout

```
claude/
  settings.json         # Claude Code user settings (hooks, plugins, flags)
  skills/               # Custom user-level skills
    pr-draft/
    verify/
  hooks/                # Shell + PowerShell hooks referenced by settings.json
Brewfile                # Homebrew packages (regenerate with `brew bundle dump`)
```

## Bootstrap a new machine

### Windows

```powershell
# 1. Clone
git clone git@github.com-ranger:max-ranger/dotfiles.git C:\Dev\ranger\dotfiles
cd C:\Dev\ranger\dotfiles

# 2. Link Claude config into %USERPROFILE%\.claude\
#    (Run as admin OR enable Developer Mode for symlinks)
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.claude\settings.json" -Target "$PWD\claude\settings.json"
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.claude\hooks" -Target "$PWD\claude\hooks"
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.claude\skills\pr-draft" -Target "$PWD\claude\skills\pr-draft"
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.claude\skills\verify" -Target "$PWD\claude\skills\verify"
```

If symlinks aren't an option, just copy:

```powershell
Copy-Item -Recurse -Force claude\* "$env:USERPROFILE\.claude\"
```

### macOS / Linux

```bash
git clone git@github.com-ranger:max-ranger/dotfiles.git ~/dotfiles
cd ~/dotfiles

mkdir -p ~/.claude/skills
ln -sf "$PWD/claude/settings.json" ~/.claude/settings.json
ln -sf "$PWD/claude/hooks"         ~/.claude/hooks
ln -sf "$PWD/claude/skills/pr-draft" ~/.claude/skills/pr-draft
ln -sf "$PWD/claude/skills/verify"   ~/.claude/skills/verify

# Homebrew packages
brew bundle --file=Brewfile
```

## Updating

After tweaking a Claude skill, hook, or setting locally, commit and push from this repo. If you edited a symlinked file in `~/.claude/`, the change is already in the repo — just `git status` here.

To refresh the Brewfile from your current Mac:

```bash
brew bundle dump --file=Brewfile --force
git commit -am "brew: refresh package list"
```

## What's intentionally NOT here

- `~/.claude/projects/` — per-project memory and history, machine-local
- `~/.claude/plugins/` — managed by Claude Code's plugin system, restored via `enabledPlugins` in `settings.json`
- `~/.claude/cache/`, `~/.claude/telemetry/`, session state — ephemeral
- Anything matching `.gitignore` (env files, credentials, local overrides)
