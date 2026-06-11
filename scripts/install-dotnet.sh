#!/usr/bin/env bash
# Install the .NET SDK on a fresh machine.
#
# .NET is NOT managed by Homebrew in these dotfiles — it's installed via
# Microsoft's official dotnet-install.sh, pinned to the latest stable LTS
# release by default. Idempotent: skips if a .NET SDK is already installed.
#
# Usage: ./scripts/install-dotnet.sh [channel]
#   channel defaults to LTS (latest long-term-support release, e.g. .NET 10).
#   Examples:  ./scripts/install-dotnet.sh STS     # latest standard-term
#              ./scripts/install-dotnet.sh 10.0    # pin a specific line
set -euo pipefail

CHANNEL="${1:-LTS}"
INSTALL_DIR="$HOME/.dotnet"

if command -v dotnet >/dev/null 2>&1; then
  echo "✓ .NET already installed: $(dotnet --version) ($(command -v dotnet))"
  echo "  Nothing to do. Remove it first, or run dotnet-install.sh manually, to change versions."
  exit 0
fi

echo "Installing .NET SDK (channel: $CHANNEL) into $INSTALL_DIR ..."
TMP="$(mktemp)"
curl -fsSL https://dot.net/v1/dotnet-install.sh -o "$TMP"
chmod +x "$TMP"
"$TMP" --channel "$CHANNEL" --install-dir "$INSTALL_DIR"
rm -f "$TMP"

# Ensure DOTNET_ROOT + PATH are set for zsh (guarded so it's idempotent).
ZSHRC="$HOME/.zshrc"
if ! grep -q 'DOTNET_ROOT' "$ZSHRC" 2>/dev/null; then
  {
    echo ''
    echo '# .NET SDK (installed via dotfiles/scripts/install-dotnet.sh)'
    echo "export DOTNET_ROOT=\"$INSTALL_DIR\""
    echo 'export PATH="$DOTNET_ROOT:$PATH"'
  } >> "$ZSHRC"
  echo "✓ Added DOTNET_ROOT + PATH to $ZSHRC"
else
  echo "• DOTNET_ROOT already configured in $ZSHRC — left as is"
fi

echo "Done. Open a new shell (or: source \"$ZSHRC\"), then verify with: dotnet --version"
