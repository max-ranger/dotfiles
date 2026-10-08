# 0012. Notch app: keep Boring Notch

Date: 2026-08-14
Status: accepted

After trialing alternatives, Boring Notch stays as the notch app. Do not re-recommend the rejected apps below.

## Key points

- **decision:** Boring Notch remains the notch app (`boring-notch` cask via `theboredteam/boring-notch` tap)
- **tool:** Tap needs `trusted: true` in the Brewfile — newer Homebrew refuses casks from untrusted third-party taps, and the flag keeps fresh-machine `brew bundle` non-interactive
- **rationale:** MacNotch rejected: constant permission prompts, features too thin vs marketing; its "honest comparison" pages are self-published SEO
- **rationale:** NotchNook rejected: same permission nagging on the tray, feature set didn't justify the price over the free option
- **rationale:** Sapphire not tried: young solo-dev project (created 2025-11), fails the "recognized apps" bar for now
- **convention:** Window snapping stays with Rectangle, not a notch app; Finder file moves via ⌘C then ⌘⌥V (macOS-native cut-paste)
- **constraint:** Apps removed via AppCleaner leave their brew cask registration behind — follow up with `brew uninstall --cask <name>`; a running notch app reads as "protected" in AppCleaner, quit it first
