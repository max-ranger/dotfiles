# Feature PR template — 🚀

Use for new functionality (`feature/`, `feat/`) and as the generic fallback for `Change`.

```markdown
### 📝 Description

<2-4 sentence summary of what changed and why, based on the diff and commits. Focus on the WHY.>

💪 **Highlights**

<bullet list of key changes — concrete and specific to the diff, no filler>

---

### 🧪 Testing Instructions

<numbered steps a reviewer follows to validate the changes — specific to what actually changed>

---

### 📷 Screenshots & Recordings

<Only if UI files changed — otherwise remove this section.>

|         |         |
|  :----  | :-----: |
| Before | _to be added_ |
| After  | _to be added_ |

---

### 🧰 Dependencies & Requirements

<new dependencies (check package manifest diff), env vars, migrations — or "None">

---

### 🚪 Merge Danger

**Door:** <one-way or two-way — can this be rolled back by reverting the PR, or does it migrate data, delete, or change a public contract?>
**Blast radius:** <what else moves if this is wrong: consumers, layout, mobile, other repos>

---

### 💥 Breaking Changes & Alerts

<breaking changes: removed/renamed exports, changed interfaces, API changes — or "None">
```
