# Refactor PR template — ♻️

Use for `refactor/` branches — internal restructuring with no intended change in behavior.

```markdown
### 🎯 Motivation

<why this refactor now — the pain it removes (readability, coupling, duplication, perf, testability). Focus on the WHY.>

---

### ♻️ What Changed

<the structural changes — moved/renamed/extracted/collapsed. Describe the shape change, not a file-by-file dump.>

---

### ✅ Behavior Preservation

**No functional or behavioral change intended.** <Note anything a reviewer should know about how equivalence was preserved — same inputs/outputs, same side effects.>

---

### 🌐 Blast Radius

<what this touches: modules, call sites, public vs internal surface. Where should a reviewer look hardest?>

---

### 🧪 How Verified

<evidence behavior is unchanged: existing tests pass, added characterization tests, manual parity check, benchmarks if perf-motivated>

---

### 💥 API / Signature Changes

<changed signatures, moved exports, renamed public symbols that downstream code depends on — or "None, internal only">
```
