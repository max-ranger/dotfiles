# Hotfix PR template — 🩹

Use for `hotfix/` branches — an urgent fix to a live/production issue. Tone is terse and impact-first.

```markdown
> 🩹 **Hotfix** — expedited review requested.

### 🚨 Severity & Impact

<what is broken in production, who/what is affected, and how urgent. Include severity (e.g. Sev1/Sev2) and any incident link.>

---

### 🔍 Root Cause

<the underlying cause — kept short. Deeper analysis can go in the follow-up.>

---

### 🩹 The Fix

<the minimal change made to stop the bleeding. Call out that scope was kept deliberately small.>

---

### ⏪ Rollback Plan

<how to revert safely if this makes things worse — revert commit, feature flag, config toggle, redeploy previous build>

---

### 🧪 Verification

<how the fix was validated under production-like conditions before/at merge — the bar is "proven safe to ship now">

---

### 📌 Follow-up

<deferred work: proper fix, tests, post-mortem, tech-debt ticket. Link the follow-up issue — or "None">
```
