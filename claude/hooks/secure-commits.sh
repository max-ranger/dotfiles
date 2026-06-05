#!/bin/bash
# Scans staged content for secrets before `git commit` (PreToolUse Bash).

source ~/.claude/hooks/_parse-input.sh
[ -z "$HOOK_COMMAND" ] && exit 0

# Only trigger on git commit
if ! echo "$HOOK_COMMAND" | grep -qE '(^|[;&|()]+[[:space:]]*)git[[:space:]]+commit(\b|$)'; then
  exit 0
fi

emit() {
  local decision="$1" reason="$2"
  reason=${reason//\\/\\\\}
  reason=${reason//\"/\\\"}
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"%s"}}\n' "$decision" "$reason"
  exit 2
}
deny() { emit deny "DANGER - SecureCommits: $1"; }
ask()  { emit ask  "SecureCommits: $1"; }

STAGED=$(git diff --cached --name-only 2>/dev/null)
[ -z "$STAGED" ] && exit 0

# ── .env files (allow .example/.sample/.template/.dist variants) ──
BAD_ENV=$(echo "$STAGED" | grep -E '(^|/)\.env($|\.[^/]+$)' | grep -vE '\.(example|sample|template|dist)(\.|$)' || true)
if [ -n "$BAD_ENV" ]; then
  LIST=$(echo "$BAD_ENV" | tr '\n' ',' | sed 's/,$//')
  deny ".env file(s) staged: $LIST. Use .env.example instead."
fi

# ── key/credential files ──
BAD_KEYS=$(echo "$STAGED" | grep -iE '\.(pem|pfx|p12|keystore|jks)$|(^|/)id_rsa$|(^|/)id_ed25519$' || true)
if [ -n "$BAD_KEYS" ]; then
  LIST=$(echo "$BAD_KEYS" | tr '\n' ',' | sed 's/,$//')
  deny "credential file(s) staged: $LIST."
fi

# ── scan staged diff (added lines only) ──
ADDED=$(git diff --cached 2>/dev/null | grep -E '^\+[^+]' || true)
[ -z "$ADDED" ] && exit 0

M=""
echo "$ADDED" | grep -qE 'AKIA[0-9A-Z]{16}' && M="$M AWS-key;"
echo "$ADDED" | grep -qiE '(aws_secret_access_key|aws_secret)[[:space:]]*[=:][[:space:]]*["\x27]?[A-Za-z0-9/+=]{40}' && M="$M AWS-secret;"
echo "$ADDED" | grep -qE '(ghp_|gho_|ghs_|ghr_|github_pat_)[a-zA-Z0-9_]{20,}' && M="$M GitHub-token;"
echo "$ADDED" | grep -qE 'sk-(ant-|proj-)?[a-zA-Z0-9_-]{20,}' && M="$M API-key(sk-);"
echo "$ADDED" | grep -qE '(sk|rk|pk)_(live|test)_[a-zA-Z0-9]{20,}' && M="$M Stripe-key;"
echo "$ADDED" | grep -qE 'xox[bpras]-[0-9a-zA-Z-]{10,}' && M="$M Slack-token;"
echo "$ADDED" | grep -qE -- '-----BEGIN[[:space:]]+(RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----' && M="$M private-key;"
echo "$ADDED" | grep -qE '(mongodb|postgres|postgresql|mysql|redis|amqp)(\+[a-z]+)?://[^:[:space:]/@]+:[^@[:space:]]+@[^[:space:]/]+' && M="$M conn-string-with-creds;"

if echo "$ADDED" | grep -qiE '(password|secret|api[_-]?key|api[_-]?token)[[:space:]]*[=:][[:space:]]*["\x27][^"\x27$\{]{12,}["\x27]'; then
  if ! echo "$ADDED" | grep -qiE 'process\.env|os\.environ|getenv|\$\{|env\(|ENV\[|import\.meta\.env'; then
    M="$M hardcoded-credential-literal;"
  fi
fi

[ -n "$M" ] && ask "possible secret(s) in staged diff:$M Run git diff --cached to review."
exit 0
