# 🧰 dotfiles

> A reference for setting up a new machine the way I like it — **Claude Code, Homebrew, Git,
> .NET, and VS Code**, each with notes on *what it's for* and *how to put it in place*.

**📋 It's documentation, not an auto-syncing setup.** Nothing here is symlinked or run
automatically. On a new machine you *copy* what you want into place. When you find a better way
to do something, change the live file and copy it back here by hand. The repo is the canonical
record of the preferred setup, kept current manually.

🖥️ Primary target is **macOS** (Apple Silicon). Every step also has a **Windows** variant using
[winget](https://learn.microsoft.com/windows/package-manager/), the package manager built into
Windows 10/11 — Homebrew doesn't run on Windows, so winget is its stand-in there.

---

## 📑 Contents

1. [⚡ Quick setup — zero to working](#-quick-setup--zero-to-working)
2. [🍺 Homebrew — apps, CLIs & fonts](#-homebrew--apps-clis--fonts)
3. [📜 Scripts — .NET SDK (outside brew)](#-scripts--net-sdk-outside-brew)
4. [🌿 Git — config, SSH keys & signed commits](#-git--config-ssh-keys--signed-commits)
5. [🤖 Claude Code — config, hooks, plugins & skills](#-claude-code--config-hooks-plugins--skills)
6. [🧩 VS Code — settings, keybindings & extensions](#-vs-code--settings-keybindings--extensions)
7. [🔄 Maintaining this repo](#-maintaining-this-repo)
8. [🙏 Credits — third-party skills & plugins](#-credits--third-party-skills--plugins)

---

## ⚡ Quick setup — zero to working

The fastest path: bootstrap the package manager, clone this repo, install everything in the
Brewfile, then **hand the rest to Claude Code** — point the AI at this repo and let it run the
per-tool copy steps for you. 🤖

### 🍎 macOS

```bash
# 1. Homebrew (its installer also pulls in Xcode Command Line Tools → you get git for free)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"        # add brew to PATH for this shell

# 2. Clone this repo (no SSH key yet? use the HTTPS line instead)
git clone git@github.com-ranger:max-ranger/dotfiles.git ~/dotfiles
# git clone https://github.com/max-ranger/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 3. Install everything in one shot — CLIs, apps, fonts, AND VS Code extensions
brew bundle --file=brew/Brewfile

# 4. Install Claude Code, open it in the repo, and let the AI finish the setup
curl -fsSL https://claude.ai/install.sh | bash       # or: npm install -g @anthropic-ai/claude-code
claude
```

Then, inside `claude`, just ask:

> **"Set up this machine from these dotfiles — copy the Claude, VS Code and Git configs into
> place per the README, and run the .NET install script."**

Claude reads this README and runs the copy/install steps below for you. ✨

### 🪟 Windows

```powershell
# 1. winget ships with Windows 10/11 (App Installer). Get git, then clone:
winget install Git.Git
git clone https://github.com/max-ranger/dotfiles.git C:\Dev\ranger\dotfiles
cd C:\Dev\ranger\dotfiles

# 2. No Homebrew on Windows — install the apps you want with winget (see the Homebrew section)
# 3. Install Claude Code and let the AI finish the rest
irm https://claude.ai/install.ps1 | iex                # or: npm install -g @anthropic-ai/claude-code
claude
```

> 💡 Every `cp` / `Copy-Item` command below assumes you're **inside the cloned repo**. Re-run any
> of them to refresh from the repo — they just overwrite.

---

## 🍺 Homebrew — apps, CLIs & fonts

**What it is:** [Homebrew](https://brew.sh) is the de-facto package manager for macOS (and Linux).
One `brew install` grabs CLI tools (*formulae*), GUI apps (*casks*), and even fonts. The
[`brew/Brewfile`](brew/Brewfile) is a single manifest of **everything** this setup wants — it
also installs **VS Code extensions** (the `vscode "…"` lines), so editor plugins are managed here
too.

**Install Homebrew + everything:**

```bash
# macOS — install brew (step 1 of Quick Setup), then:
brew bundle --file=brew/Brewfile
```

```powershell
# Windows — Homebrew isn't supported. Install equivalents with winget by hand
# (the Brewfile stays the macOS/Linux source of truth for what to install):
winget install Microsoft.VisualStudioCode Google.Chrome Obsidian.Obsidian `
               Docker.DockerDesktop JetBrains.Toolbox Spotify.Spotify Zoom.Zoom `
               Git.Git GitHub.cli BurntSushi.ripgrep.MSVC jqlang.jq Schniz.fnm
```

### 🛠️ CLI tools (formulae)

| Tool | What it's for |
|---|---|
| `bat` | `cat` with syntax highlighting + git integration |
| `cocoapods` | Dependency manager for Cocoa / iOS projects |
| `coreutils` | GNU file, shell & text utilities |
| `direnv` | Auto-load/unload env vars per directory (`$PWD`) |
| `docker` · `docker-compose` | Container CLI + multi-container orchestration |
| `eza` | Modern, maintained `ls` replacement |
| `fnm` | Fast Node.js version manager |
| `fvm` | Flutter SDK version manager (per project) |
| `fzf` | Command-line fuzzy finder |
| `gh` | GitHub CLI |
| `git` | Version control (the whole point 😉) |
| `gnupg` | OpenPGP / GPG |
| `htop` | Interactive process viewer |
| `jq` | Command-line JSON processor |
| `pnpm` | Fast, disk-efficient package manager |
| `ripgrep` | Blazing-fast `grep` replacement |
| `starship` | Cross-shell prompt |
| `tree` | Render directories as trees |
| `uv` | Extremely fast Python package installer (Rust) |
| `wget` | Internet file retriever |
| `zoxide` | Smarter `cd` that learns your habits |

### 📦 Apps (casks)

| App | What it's for |
|---|---|
| `visual-studio-code` | Primary editor / IDE (see VS Code section) |
| `warp` | Rust-based terminal |
| `orbstack` | Fast, light Docker Desktop replacement |
| `postgres-app` | One-click PostgreSQL on macOS |
| `fork` | Git GUI client |
| `jetbrains-toolbox` | Manages Rider / WebStorm / etc. |
| `flutter` | Flutter SDK |
| `google-chrome` | Web browser |
| `obsidian` | Markdown knowledge base (also basic-memory's graph) |
| `claude` | Anthropic's Claude desktop app |
| `spotify` · `zoom` | Music · video calls |
| `rectangle` | Keyboard window snapping |
| `dockdoor` | Window peeking on Dock hover |
| `boring-notch` | Turns the notch into a media widget 🎸 |
| `appcleaner` | Clean app uninstaller |
| `font-hack-nerd-font` | Hack Nerd Font (terminal + editor font) |

> ➕ The Brewfile also installs two non-brew bits via `brew bundle`: **`basic-memory`** (through
> `uv` — the knowledge-graph backend Claude uses) and **`corepack`** (through `npm`).

---

## 📜 Scripts — .NET SDK (outside brew)

**Why a script and not brew?** A few things are better installed from their vendor than from
Homebrew. The **.NET SDK** is the main one: Microsoft ships an official installer that handles
channels (LTS/STS) and side-by-side versions cleanly, so this repo uses that instead of a brew
formula.

[`scripts/install-dotnet.sh`](scripts/install-dotnet.sh) runs Microsoft's `dotnet-install.sh`
into `~/.dotnet`, pinned to the **latest LTS** by default. It's **idempotent** (skips if .NET is
already present) and wires `DOTNET_ROOT` + `PATH` into your `~/.zshrc`.

```bash
# macOS / Linux
./scripts/install-dotnet.sh          # LTS by default
./scripts/install-dotnet.sh STS      # latest standard-term release
./scripts/install-dotnet.sh 10.0     # pin a specific line
```

```powershell
# Windows — the shell script doesn't run; use winget (or the official installer)
winget install Microsoft.DotNet.SDK.10
```

After install, open a new shell (or `source ~/.zshrc`) and verify:

```bash
dotnet --version
```

---

## 🌿 Git — config, SSH keys & signed commits

**What it is:** Git is the distributed version-control system everything here runs on. Install it
via Homebrew (`brew "git"`, included in the Brewfile) or `winget install Git.Git` on Windows.

### 1️⃣ First-time identity

```bash
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"     # use a VERIFIED GitHub email
git config --global init.defaultBranch main
```

### 2️⃣ One SSH key for **both** auth and signing 🔑

This setup uses a single SSH key (`~/.ssh/ssh-key`) to *authenticate pushes* **and** *sign
commits*, so commits show the **Verified** ✅ badge on GitHub.

```bash
# Create the key if you don't have one yet
ssh-keygen -t ed25519 -C "you@example.com" -f ~/.ssh/ssh-key
ssh-add ~/.ssh/ssh-key                  # load into the agent
```

```powershell
# Windows (OpenSSH ships with Windows 10/11)
ssh-keygen -t ed25519 -C "you@example.com" -f $env:USERPROFILE\.ssh\ssh-key
```

**Tell git to SSH-sign** (global; lives in `~/.gitconfig`, which this repo does not track):

```bash
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/ssh-key
git config --global commit.gpgsign true
```

```powershell
# Windows — if signing fails, point git at OpenSSH's signer:
git config --global gpg.ssh.program "C:/Windows/System32/OpenSSH/ssh-keygen.exe"
```

**Register the key on GitHub _twice_ — ⚠️ gotcha #1.** *Authentication* and *Signing* keys are
separate entries even for identical key bytes. Add `~/.ssh/ssh-key.pub` once for push/pull, then
again at **Settings → SSH and GPG keys → New SSH key → Key type: _Signing Key_**. Also make sure
the commit email is a **verified** email on the account (**⚠️ gotcha #2** — else GitHub reports
`unverified_email`). GitHub verifies dynamically, so this flips already-pushed commits to Verified
too — no re-commit needed.

**Let git verify locally** (else `git log --show-signature` errors on a missing
`allowedSignersFile`):

```bash
mkdir -p ~/.config/git
echo "$(git config user.email) $(cat ~/.ssh/ssh-key.pub)" >> ~/.config/git/allowed_signers
git config --global gpg.ssh.allowedSignersFile ~/.config/git/allowed_signers
git log --show-signature -1     # should print: Good "git" signature for <email>
```

> 🔒 No keys or signer files are tracked in this repo — by design. `~/.ssh/*` and
> `~/.config/git/allowed_signers` are machine-local identity/secrets; the commands above
> regenerate the signer file from whatever key the machine already holds.

### 3️⃣ The project `.gitignore` 🚫

[`git/gitignore`](git/gitignore) is an all-purpose ignore tuned for this stack —
**C# / .NET · TypeScript · Vue · Tailwind · Node (Vite)** across **Visual Studio, JetBrains
(Rider/WebStorm) and VS Code**. It's reconciled against the official `github/gitignore` templates
and covers: secrets & `.env*`, keys/certs, `appsettings*.json`, `node_modules` & build output
(`dist/`, `bin/`, `obj/`), test/coverage artifacts, IDE folders, OS junk, and local Claude/AI
files. Lockfiles (`package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`) stay **committed**.

```bash
cp ~/dotfiles/git/gitignore ./.gitignore          # macOS / Linux
```
```powershell
Copy-Item C:\Dev\ranger\dotfiles\git\gitignore .\.gitignore   # Windows
```

---

## 🤖 Claude Code — config, hooks, plugins & skills

**What it is:** [Claude Code](https://claude.com/claude-code) is Anthropic's agentic coding tool
that runs in your terminal (and IDE). This section is the **global** setup that applies across
every project: instructions, automation hooks, enabled plugins, and personal skills.

**Install:**

```bash
curl -fsSL https://claude.ai/install.sh | bash       # macOS / Linux
# or: npm install -g @anthropic-ai/claude-code
```
```powershell
irm https://claude.ai/install.ps1 | iex              # Windows
```

> The `claude` **desktop app** is separate and installs via Homebrew (`cask "claude"`); the
> `anthropic.claude-code` **VS Code extension** installs via the Brewfile.

### ⚙️ Config files

- [`claude/CLAUDE.md`](claude/CLAUDE.md) — global user instructions: harness/workflow rules
  (commit hygiene, PR-via-`pr-draft`, hard-gate hooks, loop discipline) + the **basic-memory**
  knowledge-graph protocol.
- [`claude/settings.json`](claude/settings.json) — hooks wiring, `enabledPlugins` +
  `extraKnownMarketplaces` (installed on Claude Code startup), and flags (`effortLevel`, `theme`,
  push notifications).
- [`claude/hooks/`](claude/hooks) — shell + PowerShell hooks: **security gate**, **secure-commits**,
  **commit-hygiene**, **pre-commit checks**, **format-on-save**, **desktop notifications**, and
  **basic-memory session context**.
- [`claude/skills/`](claude/skills) — user-level skills: `pr-draft` (own), plus the vendored
  `emil-design-eng` and `design-taste-frontend` (see credits).

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
Copy-Item          claude\CLAUDE.md                    "$env:USERPROFILE\.claude\CLAUDE.md"
Copy-Item          claude\settings.json                "$env:USERPROFILE\.claude\settings.json"
Copy-Item -Recurse claude\hooks                        "$env:USERPROFILE\.claude\hooks"
Copy-Item -Recurse claude\skills\pr-draft              "$env:USERPROFILE\.claude\skills\pr-draft"
Copy-Item -Recurse claude\skills\emil-design-eng       "$env:USERPROFILE\.claude\skills\emil-design-eng"
Copy-Item -Recurse claude\skills\design-taste-frontend "$env:USERPROFILE\.claude\skills\design-taste-frontend"
```

### 🧠 Per-project template

[`claude/repo-template/CLAUDE.md`](claude/repo-template/CLAUDE.md) seeds a new project's
`.claude/CLAUDE.md` (auto-loads like a root `CLAUDE.md` and **composes** with the global one —
don't restate global rules in a project file).

```bash
mkdir -p .claude && cp ~/dotfiles/claude/repo-template/CLAUDE.md ./.claude/CLAUDE.md   # macOS/Linux
```
```powershell
New-Item -ItemType Directory -Force .claude | Out-Null
Copy-Item C:\Dev\ranger\dotfiles\claude\repo-template\CLAUDE.md .\.claude\CLAUDE.md     # Windows
```

### 🔌 Plugins & skills in use

Installed automatically on startup from `settings.json` → `enabledPlugins`.

**From the official `claude-plugins-official` marketplace:**
`frontend-design` · `code-review` · `claude-md-management` · `claude-code-setup` ·
`code-simplifier` · `superpowers` · `context7` · `skill-creator` · `feature-dev` ·
`typescript-lsp` · `security-guidance` · `commit-commands`.

**Third-party marketplaces** (declared in `extraKnownMarketplaces`):
- `andrej-karpathy-skills` — [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)
- `ui-ux-pro-max` — [nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill)
- `impeccable` — [pbakaus/impeccable](https://github.com/pbakaus/impeccable)
- `warp` — [warpdotdev/claude-code-warp](https://github.com/warpdotdev/claude-code-warp)

**Vendored skills** (copied into `claude/skills/`, pinned): `pr-draft` (own), plus
`emil-design-eng` & `design-taste-frontend` (see credits).

> 🧠 **basic-memory** backs the knowledge-graph protocol in `CLAUDE.md` — installed via the
> Brewfile (`uv "basic-memory"`) and rendered as an Obsidian vault.

---

## 🧩 VS Code — settings, keybindings & extensions

**What it is:** [Visual Studio Code](https://code.visualstudio.com) is the primary editor.
Install all the extensions below and it becomes a **basic but fully functioning IDE** for this
stack — **.NET / C# · PostgreSQL · Docker · Vue.js · Tailwind** — with formatting, linting,
IntelliSense, and Git tooling wired up. 🚀

> Extensions are **not** copied here — they install via the Brewfile (`vscode "…"` lines). Only
> `settings.json` and `keybindings.json` live in this folder.

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

### 🎛️ Settings highlights ([`vscode/settings.json`](vscode/settings.json))

- 🔤 **Font:** Hack Nerd Font Mono @ 12 (editor + terminal); **theme:** Dark 2026.
- ↹ **Indent:** 4 spaces, no auto-detect; trim trailing whitespace.
- ✨ **Format on save** via Prettier for JS/TS(X) + Astro; **ESLint** `fixAll` + add-missing-imports
  on save (other languages don't auto-format).
- 🤝 **GitHub Copilot** + next-edit suggestions on; **Claude Code** docked in the sidebar.
- 🌳 **GitLens / git-graph** tuned; `.env*` files highlighted as makefiles for visibility.

### ⌨️ Keybindings ([`vscode/keybindings.json`](vscode/keybindings.json))

Rebinds **column (box) selection** to `Shift+Cmd+↑/↓` (from the default `Shift+Alt+Cmd+↑/↓`) for
faster multi-cursor editing.

> 🪟 The keybindings use `cmd` (macOS). On Windows, swap `cmd` → `ctrl` in the copied file.

### 🧰 Extensions (installed via the Brewfile)

| Group | Extensions |
|---|---|
| **.NET / C#** | C# Dev Kit, C#, .NET Runtime |
| **Vue / Web / TS** | ESLint, Prettier, npm-intellisense, JS snippets, pretty-ts-errors, auto-close/rename-tag, styled-components, MDX |
| **Tailwind** | Tailwind CSS IntelliSense, Tailwind Docs, Headwind, Tailwind Fold |
| **Git** | Git Graph |
| **AI** | Claude Code |
| **Editor UX** | Better Comments, GitHub Theme, Color Highlight, Todo Highlight, dotenv, font-size shortcuts, status-bar format toggle |

---

## 🔄 Maintaining this repo

Nothing is symlinked, so live files and this repo **don't sync automatically** — that's the point.
When you improve a hook, skill, setting, or template:

1. ✏️ Make the change in the live location (or here in the repo).
2. 🔁 Copy it the other way so both match — re-run the relevant command above, or copy the edited
   live file back into the repo.
3. 💾 Commit and push from this repo.

Refresh the Brewfile (and tracked VS Code extensions) from the current Mac:

```bash
brew bundle dump --file=brew/Brewfile --force
git commit -am "chore(brew): refresh package list"
```

### 🙈 Not tracked here (on purpose)

- `~/.claude/projects/` — per-project memory and history, machine-local.
- `~/.claude/plugins/` — managed by Claude Code's plugin system, restored via `enabledPlugins`.
- `~/.claude/cache/`, `~/.claude/telemetry/`, session state — ephemeral.
- `~/.ssh/` keys and `~/.config/git/allowed_signers` — machine-local SSH identity/signer list.
- Anything matching `.gitignore` (env files, credentials, local overrides).

---

## 🙏 Credits — third-party skills & plugins

**Vendored skills** (copied into `claude/skills/`, pinned — refresh by re-downloading `SKILL.md`):
- `emil-design-eng` — [emilkowalski/skill](https://github.com/emilkowalski/skill)
- `design-taste-frontend` — [bnd-1/taste-skill](https://github.com/bnd-1/taste-skill)

**Plugin marketplaces** (declared in `settings.json`, installed by Claude Code on startup):
- `andrej-karpathy-skills@karpathy-skills` — [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)
- `ui-ux-pro-max@ui-ux-pro-max-skill` — [nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill)
- `impeccable@impeccable` — [pbakaus/impeccable](https://github.com/pbakaus/impeccable)
- `warp@claude-code-warp` — [warpdotdev/claude-code-warp](https://github.com/warpdotdev/claude-code-warp)

Other enabled plugins come from the official `claude-plugins-official` marketplace.
