# pr: creating the PR on Azure DevOps

Read by `pr` Step 4 when the remote is Azure DevOps (`dev.azure.com` / `visualstudio.com`).
The org, project and repo come from the remote URL parsed in Step 1.

**Azure DevOps, `az` available with the `azure-devops` extension:**

Four constraints, each verified the hard way — read these *before* composing the body:

1. **`description` is hard-capped at 4000 characters.** 4000 succeeds; 4001 returns `400 Bad Request`.
   Compose to fit. If the content genuinely needs more, keep the description reviewer-facing and put
   only reviewer-relevant overflow (detailed test steps, breaking changes) in the PR's first comment
   thread — ticket-level narrative belongs in the ticket, not the PR.
2. **Some typographic characters are rejected** in `title` and `description` with an unhelpful 400 —
   em dashes, en dashes and curly quotes among them. ASCII-fold before sending: `—`/`–` → `-`,
   curly quotes → straight quotes, `…` → `...`, NBSP → space. (Emoji are separately unwanted; see Step 2.)
3. **`az repos pr create` passes the description as a command-line argument**, so a long body blows the
   Windows ~8191-character command-line limit and fails with "The command line is too long." Keep the
   description short, or use the REST API below.
4. **`az` may be installed but absent from PATH.** Before concluding it is missing, check
   `C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd` — a bare `command -v az` gives a false negative.

If the extension isn't installed yet, add it once: `az extension add --name azure-devops`.
Azure Repos PRs have no separate title field for the body — the description IS the body,
so put the title as an `# H1` on its own first line as well as in `--title`.

```bash
# Push branch if not tracking remote
git push -u origin <branch>

# <org>/<project>/<repo> from the remote URL parsed in Step 1.
az repos pr create \
  --organization "https://dev.azure.com/<org>" \
  --project "<project>" \
  --repository "<repo>" \
  --source-branch "<branch>" \
  --target-branch "<base-branch>" \
  --title "<title>" \
  --description "$(cat <<'EOF'
# <title>

<filled template body from Step 3>
EOF
)"
```

The command returns JSON with `pullRequestId`. Report the PR URL to the user as
`https://dev.azure.com/<org>/<project>/_git/<repo>/pullrequest/<pullRequestId>`.

**Azure DevOps via REST — use this when the description is more than a few hundred characters.**
It avoids the command-line limit entirely and is the reliable path on Windows. It reuses the
existing `az login`, so no PAT is needed and no credential is ever handled in plain text. Build the
JSON in-process and send it as UTF-8 bytes with `-ContentType 'application/json'` — do **not** put
`Content-Type` in the headers hashtable and do **not** append `charset=utf-8`; either makes
PowerShell 5.1 mangle the body, and the API then reports misleading errors like
"Both a source and target reference is required."

```powershell
$env:PATH = "C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin;$env:PATH"
$token   = az account get-access-token --resource "499b84ac-1321-427f-aa17-267ca6975798" --query accessToken -o tsv
$headers = @{ Authorization = "Bearer $token" }
$base    = "https://dev.azure.com/<org>/$([uri]::EscapeDataString('<project>'))/_apis/git/repositories/<repo>"

function Send-Json($Method, $Uri, $Object) {
    $json = $Object | ConvertTo-Json -Depth 6 -Compress
    Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers `
        -ContentType 'application/json' -Body ([System.Text.Encoding]::UTF8.GetBytes($json))
}

# Create (description must already be ASCII-folded and <= 4000 chars)
$pr = Send-Json Post "$base/pullrequests?api-version=7.1" @{
    sourceRefName = "refs/heads/<branch>"
    targetRefName = "refs/heads/<base-branch>"
    title         = "<title>"
    description   = $desc
}

# Optional: reviewer-facing overflow as the first comment thread (much larger limit)
Send-Json Post "$base/pullRequests/$($pr.pullRequestId)/threads?api-version=7.1" @{
    comments = @(@{ parentCommentId = 0; content = $overflow; commentType = 1 })
    status   = 1
}
```

**Never probe field limits against a live PR** — a failed `PATCH` leaves the last successful value
in place, so a length probe can silently overwrite a real description with filler.
