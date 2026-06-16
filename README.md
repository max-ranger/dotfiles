# dotfiles

Personal machine setup — Claude Code configs, hooks, custom skills, and package lists. Shared across machines.

## Layout

```
claude/
  CLAUDE.md             # Global user instructions (basic-memory protocol) → ~/.claude/CLAUDE.md
  settings.json         # Claude Code user settings (hooks, plugins, flags)
  skills/               # User-level skills
    pr-draft/               # own — draft PR generator
    emil-design-eng/        # vendored — emilkowalski/skill (motion/design eng)
    design-taste-frontend/  # vendored — bnd-1/taste-skill (anti-generic UI)
  hooks/                # Shell + PowerShell hooks referenced by settings.json
  templates/
    CLAUDE.md           # Starter CLAUDE.md → copy into a project's .claude/
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

## Bootstrap a new machine

### Windows

```powershell
# 1. Clone
git clone git@github.com-ranger:max-ranger/dotfiles.git C:\Dev\ranger\dotfiles
cd C:\Dev\ranger\dotfiles

# 2. Link Claude config into %USERPROFILE%\.claude\
#    (Run as admin OR enable Developer Mode for symlinks)
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.claude\CLAUDE.md" -Target "$PWD\claude\CLAUDE.md"
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.claude\settings.json" -Target "$PWD\claude\settings.json"
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.claude\hooks" -Target "$PWD\claude\hooks"
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.claude\skills\pr-draft" -Target "$PWD\claude\skills\pr-draft"

# VS Code user config (settings + keybindings; extensions install via the Brewfile)
New-Item -ItemType SymbolicLink -Path "$env:APPDATA\Code\User\settings.json"    -Target "$PWD\vscode\settings.json"
New-Item -ItemType SymbolicLink -Path "$env:APPDATA\Code\User\keybindings.json" -Target "$PWD\vscode\keybindings.json"
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
ln -sf "$PWD/claude/CLAUDE.md"     ~/.claude/CLAUDE.md
ln -sf "$PWD/claude/settings.json" ~/.claude/settings.json
ln -sf "$PWD/claude/hooks"         ~/.claude/hooks
ln -sf "$PWD/claude/skills/pr-draft" ~/.claude/skills/pr-draft

# VS Code user config (settings + keybindings; extensions install via the Brewfile)
VSC="$HOME/Library/Application Support/Code/User"
ln -sf "$PWD/vscode/settings.json"    "$VSC/settings.json"
ln -sf "$PWD/vscode/keybindings.json" "$VSC/keybindings.json"

# Homebrew packages (installs casks + VS Code extensions too)
brew bundle --file=brew/Brewfile

# .NET SDK — not managed by Homebrew; installs via Microsoft's official
# installer (latest LTS). Idempotent: skips if .NET is already present.
./scripts/install-dotnet.sh
```

## Starting a new project

Seed the project's Claude memory from the template — it lives in `.claude/`
(`.claude/CLAUDE.md` auto-loads exactly like a root `CLAUDE.md`) — then tailor:

```bash
mkdir -p .claude
cp ~/dotfiles/claude/templates/CLAUDE.md ./.claude/CLAUDE.md   # Windows: copy from C:\Dev\ranger\dotfiles\
cp ~/dotfiles/git/gitignore ./.gitignore                       # generic all-purpose ignore for the stack
```

The template is a living document — improvements you discover in a project worth keeping across all projects should be ported back into `claude/templates/CLAUDE.md` here.

## Updating

After tweaking a Claude skill, hook, or setting locally, commit and push from this repo. If you edited a symlinked file in `~/.claude/`, the change is already in the repo — just `git status` here.

To refresh the Brewfile from your current Mac (package descriptions are included by default now):

```bash
brew bundle dump --file=brew/Brewfile --force
git commit -am "brew: refresh package list"
```

VS Code `settings.json` and `keybindings.json` are symlinked into `~/Library/Application Support/Code/User/`, so edits you make in VS Code land in this repo automatically — just `git status` here. Installed extensions are tracked inline in `brew/Brewfile` (the `vscode "..."` lines) and refresh with the `brew bundle dump` above.

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
- Anything matching `.gitignore` (env files, credentials, local overrides)
