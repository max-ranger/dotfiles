# 0007. SSH commit signing — one key for auth and signing

Date: 2026-06-22
Status: accepted

Commits are SSH-signed with a single machine key (`~/.ssh/ssh-key`) so they show **Verified** on
GitHub. The same key both authenticates pushes and signs commits — "one key to rule them all."

## Context
Commits were showing **Unverified** on GitHub. Root cause: the SSH key had been added to GitHub
for authentication only. SSH signing was configured locally and producing signed commits, but
GitHub had no *signing* key registered, and local verification was unconfigured.

## Key points
- **technical:** Global git config (in ~/.gitconfig, not tracked): gpg.format=ssh, user.signingkey=~/.ssh/ssh-key, commit.gpgsign=true
- **constraint:** On GitHub the public key must be registered TWICE — once as an Authentication key, once as a Signing key (separate entries, same key bytes)
- **constraint:** The commit email must be a verified email on the GitHub account, or it reports unverified_email instead of valid
- **convention:** Local verification needs ~/.config/git/allowed_signers plus gpg.ssh.allowedSignersFile pointing at it
- **rationale:** One key for auth + signing reduces key sprawl across machines
- **risk:** GitHub verifies signatures dynamically, so registering the signing key retroactively flips already-pushed signed commits to Verified — no re-commit needed
- **constraint:** No key material or signer files are tracked in the repo; the README documents how to regenerate the allowed_signers file from the machine's key
- **tool:** On Windows, point git at OpenSSH's signer via gpg.ssh.program if signing fails
