# Bug Fix PR template — 🐛

Use for `fix/` and `bugfix/` branches.

```markdown
### 🐛 The Bug

<what was broken and the observed symptoms — what the user/system saw. Link the issue/ticket if there is one.>

---

### 🔍 Root Cause

<why it happened — the underlying cause in the code, not just the symptom. Point to the specific mechanism.>

---

### 🔧 The Fix

<what changed to resolve it, and why this is the right fix rather than a band-aid>

---

### ♻️ Reproduction

<numbered steps to reproduce the bug on the OLD code — so a reviewer can confirm it existed>

1. …
2. …

---

### 🧪 Verification & Regression

**Fixed:** <the exact test that failed before the fix and passes now, by name — or the command that showed the symptom and its output after>

**Regression watch:** <adjacent behavior a reviewer should re-check to confirm nothing else broke>

---

### 📷 Before / After

|         |         |
|  :----  | :-----: |
| Before (buggy) | _to be added_ |
| After (fixed)  | _to be added_ |

---

### 💥 Risk & Side Effects

**Door:** <one-way or two-way>
**Blast radius:** <what else this touches, edge cases considered — or "Low, isolated to the affected path">
```
