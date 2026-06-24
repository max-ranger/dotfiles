# dotfiles

A reference for setting up a new machine the way I like it — Claude Code, VS Code, Homebrew,
.NET, and Git config, each with notes on what it's for and how to put it in place.

**It's documentation, not an auto-syncing setup.** Nothing here is symlinked or run
automatically — on a new machine you *copy* what you want into place. When you find a better way
to do something, change the live file and copy it back here by hand. The repo is the canonical
record of the preferred setup, kept current manually.

## Clone first

Every tool's setup below runs from inside the cloned repo, so start here:

```bash
# macOS / Linux
git clone git@github.com-ranger:max-ranger/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

```powershell
# Windows
git clone git@github.com-ranger:max-ranger/dotfiles.git C:\Dev\ranger\dotfiles
cd C:\Dev\ranger\dotfiles
```

## Tools

Each tool: what it's for, the files involved, and how to set it up. All `cp` / `Copy-Item`
commands assume you're in the cloned repo. Re-run any of them to refresh from the repo — they
just overwrite.

### Claude Code config

*Global Claude Code setup that applies across every project.* Instructions, automation hooks,
enabled plugins, and personal skills.

- `claude/CLAUDE.md` — global user instructions (the basic-memory knowledge-graph protocol).
- `claude/settings.json` — hooks wiring, `enabledPlugins` + `extraKnownMarketplaces` (installed
  on Claude Code startup), and flags (`effortLevel`, `theme`, push notifications).
- `claude/hooks/` — shell + PowerShell hooks: security gate, secure-commits, commit hygiene,
  pre-commit checks, format-on-save, desktop notifications, and basic-memory session context.
- `claude/skills/` — user-level skills: `pr-draft` (own), `emil-design-eng`,
  `design-taste-frontend` (both vendored — see credits below).

```bash
# macOS / Linux
mkdir -p ~/.claude/skills
cp    claude/CLAUDE.md                    ~/.claude/CLAUDE.md
cp    claude/settings.json                ~/.claude/settings.json
cp -R claude/hooks                        ~/.claude/hooks
cp -R claude/skills/pr-draft              ~/.claude/skills/pr-draft
cp -R claude/skills/emil-design-eng       ~/.claude/skills/emil-design-eng
cp -R claude/skills/design-taste-frontend ~/.claude/skills/design-taste-frontend
```

```powershell
# Windows
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\skills" | Out-Null
Copy-Item          claude\CLAUDE.md                       "$env:USERPROFILE\.claude\CLAUDE.md"
Copy-Item          claude\settings.json                   "$env:USERPROFILE\.claude\settings.json"
Copy-Item -Recurse claude\hooks                           "$env:USERPROFILE\.claude\hooks"
Copy-Item -Recurse claude\skills\pr-draft                 "$env:USERPROFILE\.claude\skills\pr-draft"
Copy-Item -Recurse claude\skills\emil-design-eng          "$env:USERPROFILE\.claude\skills\emil-design-eng"
Copy-Item -Recurse claude\skills\design-taste-frontend    "$env:USERPROFILE\.claude\skills\design-taste-frontend"
```

> The two `CLAUDE.md` files differ by destination. `claude/CLAUDE.md` is the **global** one
> (cross-project behavior). `claude/repo-template/CLAUDE.md` (next tool) is the **per-project**
> seed. Both load and compose — don't restate global rules in a project file.

### Claude project template

*Seeds a new project's `.claude/` so Claude has per-project working principles.* Used when
starting a repo, not when bootstrapping a machine. `.claude/CLAUDE.md` auto-loads like a root
`CLAUDE.md` and composes with your global one.

- `claude/repo-template/CLAUDE.md` — the per-project base to tailor.

```bash
# macOS / Linux — run inside the new project
mkdir -p .claude
cp ~/dotfiles/claude/repo-template/CLAUDE.md ./.claude/CLAUDE.md
cp ~/dotfiles/git/gitignore                  ./.gitignore
```

```powershell
# Windows — run inside the new project
New-Item -ItemType Directory -Force .claude | Out-Null
Copy-Item C:\Dev\ranger\dotfiles\claude\repo-template\CLAUDE.md .\.claude\CLAUDE.md
Copy-Item C:\Dev\ranger\dotfiles\git\gitignore                  .\.gitignore
```

> The template is a living base — if you discover an improvement worth keeping across all
> projects, port it back into `claude/repo-template/CLAUDE.md` here.

### VS Code

*Editor settings and keybindings.* Extensions are not here — they install via the Brewfile.

- `vscode/settings.json`, `vscode/keybindings.json`.

```bash
# macOS / Linux
VSC="$HOME/Library/Application Support/Code/User"
mkdir -p "$VSC"
cp vscode/settings.json    "$VSC/settings.json"
cp vscode/keybindings.json "$VSC/keybindings.json"
```

```powershell
# Windows
Copy-Item vscode\settings.json    "$env:APPDATA\Code\User\settings.json"
Copy-Item vscode\keybindings.json "$env:APPDATA\Code\User\keybindings.json"
```

### Homebrew

*Packages, casks, and VS Code extensions in one manifest.* The `vscode "..."` lines in the
Brewfile install editor extensions, so VS Code extensions are managed here.

- `brew/Brewfile`.

```bash
# macOS / Linux
brew bundle --file=brew/Brewfile
```

```powershell
# Windows — Homebrew isn't supported; install equivalents with winget/scoop by hand.
# The Brewfile is the macOS/Linux source of truth for what to install.
```

### .NET SDK

*Installs the .NET SDK, which Homebrew doesn't manage here.* Uses Microsoft's official
`dotnet-install.sh` into `~/.dotnet`, pinned to the latest LTS. Idempotent — skips if .NET is
already present. Pass a channel to override (`STS`, `10.0`, …).

- `scripts/install-dotnet.sh`.

```bash
# macOS / Linux
./scripts/install-dotnet.sh          # LTS by default
```

```powershell
# Windows — the shell script doesn't run; use winget (or the official installer)
winget install Microsoft.DotNet.SDK.10
```

### Git — ignore rules + signed commits

*A generic project `.gitignore` and SSH commit signing.*

**Generic `.gitignore`** (`git/gitignore`) — an all-purpose ignore for the C#/.NET · TS/Vue ·
Node stack. Drop into a new project (also copied by the project-template step above):

```bash
cp ~/dotfiles/git/gitignore ./.gitignore          # macOS / Linux
```
```powershell
Copy-Item C:\Dev\ranger\dotfiles\git\gitignore .\.gitignore   # Windows
```

**Signed commits (SSH).** Commits are SSH-signed with the machine's one key (`~/.ssh/ssh-key`)
so they show **Verified** on GitHub — same key authenticates pushes *and* signs commits. Three
steps, with two gotchas that otherwise cause the **Unverified** badge.

1. **Tell git to SSH-sign** (global; lives in `~/.gitconfig`, which this repo does not track):
   ```bash
   git config --global gpg.format ssh
   git config --global user.signingkey ~/.ssh/ssh-key
   git config --global commit.gpgsign true
   ```
   On Windows, point git at OpenSSH's signer if signing fails:
   `git config --global gpg.ssh.program "C:/Windows/System32/OpenSSH/ssh-keygen.exe"`.

2. **Register the key on GitHub _twice_ — gotcha #1.** *Authentication* and *Signing* keys are
   separate entries even for identical key bytes; adding it for push/pull does **not** verify
   signatures. Add the same `~/.ssh/ssh-key.pub` again at **Settings → SSH and GPG keys → New
   SSH key → Key type: _Signing Key_**. Also make sure the commit email is a **verified** email
   on the account (**gotcha #2** — else GitHub reports `unverified_email`). GitHub verifies
   dynamically, so this flips already-pushed commits to Verified too — no re-commit needed.

3. **Let git verify locally** (else `git log --show-signature` errors on a missing
   `allowedSignersFile`). Build the allowed-signers file from your own key and point git at it:
   ```bash
   mkdir -p ~/.config/git
   echo "$(git config user.email) $(cat ~/.ssh/ssh-key.pub)" >> ~/.config/git/allowed_signers
   git config --global gpg.ssh.allowedSignersFile ~/.config/git/allowed_signers
   git log --show-signature -1     # should print: Good "git" signature for <email>
   ```
   Windows paths: `%USERPROFILE%\.ssh\ssh-key` and `%USERPROFILE%\.config\git\allowed_signers`.

> No keys or signer files are tracked in this repo — by design. `~/.ssh/*` and
> `~/.config/git/allowed_signers` are machine-local identity/secrets; the commands above
> regenerate the signer file from whatever key the machine already holds.

## Maintaining this repo

Nothing is symlinked, so live files and this repo **don't sync automatically** — that's the
point. When you improve a hook, skill, setting, or template:

1. Make the change in the live location (or here in the repo).
2. Copy it the other way so both match — re-run the relevant command above, or copy the edited
   live file back into the repo.
3. Commit and push from this repo.

Refresh the Brewfile (and tracked VS Code extensions) from the current Mac:

```bash
brew bundle dump --file=brew/Brewfile --force
git commit -am "brew: refresh package list"
```

## Third-party skills & plugins

**Vendored skills** (copied into `claude/skills/`, pinned — refresh by re-downloading `SKILL.md`):
- `emil-design-eng` — [emilkowalski/skill](https://github.com/emilkowalski/skill)
- `design-taste-frontend` — [bnd-1/taste-skill](https://github.com/bnd-1/taste-skill)

**Plugin marketplaces** (declared in `settings.json` → `enabledPlugins` + `extraKnownMarketplaces`,
installed by Claude Code on startup):
- `andrej-karpathy-skills@karpathy-skills` — [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)
- `ui-ux-pro-max@ui-ux-pro-max-skill` — [nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill)
- `impeccable@impeccable` — [pbakaus/impeccable](https://github.com/pbakaus/impeccable)
- `warp@claude-code-warp` — [warpdotdev/claude-code-warp](https://github.com/warpdotdev/claude-code-warp)

Other enabled plugins come from the official `claude-plugins-official` marketplace.

## Not tracked here (on purpose)

- `~/.claude/projects/` — per-project memory and history, machine-local.
- `~/.claude/plugins/` — managed by Claude Code's plugin system, restored via `enabledPlugins`.
- `~/.claude/cache/`, `~/.claude/telemetry/`, session state — ephemeral.
- `~/.ssh/` keys and `~/.config/git/allowed_signers` — machine-local SSH identity/signer list;
  see *Git → signed commits* to recreate the signer file.
- Anything matching `.gitignore` (env files, credentials, local overrides).
