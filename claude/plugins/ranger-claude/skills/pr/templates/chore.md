# Chore / Dependencies PR template — 🧹

Use for `chore/` branches — maintenance, tooling, config, and dependency/version bumps. Lightweight by design.

```markdown
### 🧹 What & Why

<1-3 sentences: what maintenance this does and why now (security patch, deprecation, cleanup, tooling upgrade).>

---

### 📦 Changes

<bullet list of concrete changes — config, CI, scripts, tooling, lockfile. Group related items.>

---

### ⬆️ Dependency Updates

<Only if deps changed — otherwise remove this section.>

| Package | From | To | Notes |
| :------ | :--- | :- | :---- |
| `<name>` | `<old>` | `<new>` | <breaking? security? none> |

---

### 🧪 Verification

<proof nothing regressed: build passes, tests green, CI checks, lockfile installs cleanly>

---

### 💥 Notes & Risks

<anything reviewers should know — breaking bumps, required re-install, migration step — or "Low risk, no behavior change">
```
