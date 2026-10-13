# 0016. Second review round: cherry-pick text, install nothing

Date: 2026-10-12
Status: accepted

## Context
Two skill collections (obra/superpowers v7.0.0, mattpocock/skills v1.3.1), three tools (markitdown, Unlimited-OCR, openai/whisper) and one app suite (Artcraft) were proposed for the setup. [0003](0003-own-the-tooling-as-the-ranger-claude-plugin.md) already says instruction-shaped tooling is owned and third-party text is vendored. Both collections were read file by file. The recurring cost that prompted the round: plans and stack choices that nobody attacked before they were built, which forced three stack resets.

## Decision
No plugin and no tool is installed. Sixteen pieces of text are distilled into the plugin as version 1.1.0, with attribution in `references/NOTICE.md`:

- New skills `grill` (batched challenge rounds; `/spec` runs one before approval) and `diagnosing-bugs` (a red-capable loop before any hypothesis).
- New always-on rule `testing.md` and `references/writing-good-tests.md`; the verifier judges tests, may not mutate git state, and treats a spec's silence as no permission.
- Plan template: interfaces per task, vertical slices, review focus. Definition of done: claims and their evidence. Simplicity rule: three module tests. PR templates: merge danger. ADRs: an offer test and a door line. Rulings carry their cost if wrong; fix loops stop after three failed fixes.

Not taken, because each contradicts a rule already chosen: test-first as an iron law, defense-in-depth layers per bug, tickets on a tracker, a session-start injection.

Tools: markitdown is skipped (it reads only a PDF's text layer and does no OCR; Claude reads PDFs natively). Unlimited-OCR is skipped (official runtimes need CUDA, no published language list or German benchmark; a scan path is better served by rasterizing pages into the multimodal model already in use). The Python whisper package is skipped (whisper.cpp already has language detection, word timestamps, VAD and the turbo model). The Artcraft apps are skipped and watched: legitimate and notarized, but days-old alpha software with lookalike download sites; re-check in 2027 and download only from the project's GitHub releases. Warp is dropped from the manifests; it was no longer used.

## Consequences
- `/spec` stops twice: for the grill answers, then for approval.
- Batched challenge rounds now exist beside the one-question interview; the interview stays for understanding an ask, the rounds are for attacking a plan.
- Upstream changes arrive only by a deliberate re-review against a new commit.
- Door: two-way; cost if wrong: revert the plugin to 1.0.1.

## Alternatives considered
- Install either collection as a plugin — two routers for the same prompts, and process rules that fight the gates.
- Take nothing — leaves debugging, test quality and plan challenge ungoverned.
