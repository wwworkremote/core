---
id: TASK-108
title: >-
  Spike: on-device inference (Chrome built-in AI) for extension-side
  sense-making
status: To Do
assignee: []
created_date: '2026-08-27 17:27'
updated_date: '2026-08-28 18:47'
labels:
  - architecture
  - sandbox-provider
  - spike
dependencies:
  - TASK-104
references:
  - TASK-112
  - 'https://developer.chrome.com/docs/extensions/reference/api/debugger'
  - 'https://developer.chrome.com/docs/ai/prompt-api'
  - 'https://developer.chrome.com/docs/extensions/reference/api/offscreen'
documentation:
  - docs/architecture/sandbox-provider.md
  - docs/research/chrome-built-in-ai-flags.md
  - docs/research/chrome-platform-and-wasm-leverage.md
priority: low
type: spike
ordinal: 700
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
docs/architecture/sandbox-provider.md, "Worth considering while the harness is being built: on-device inference" section.

Modern Chrome ships built-in AI (Prompt API, Summarizer, Writer/Rewriter, Language Detector -- all on-device via Gemini Nano, available to extensions, no network round-trip). This repo's extension already does some classification server-side (ApplicationFieldQuestionClassifier, LLM::Orchestrator). Worth evaluating whether some of that -- specifically sense-making's first-pass field classification on an unfamiliar provider -- is a good fit for on-device inference instead, to distribute load off the backend and cut round-trip latency during capture.

Explicitly a spike: evaluate and report, not a commitment to build. Depends on TASK-104 (sandbox provider) existing, since that's the concrete thing to point an evaluation at rather than designing this in the abstract.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Confirms current availability/stability of the relevant Chrome built-in AI APIs for extensions (Prompt API in particular) as of whenever this spike runs -- these are actively evolving
- [ ] #2 A small prototype (or documented reasoning why not) showing on-device classification of at least one real field-classification case against the sandbox provider
- [ ] #3 A recommendation: adopt, defer, or reject, with reasoning -- this task's output is a decision, not necessarily shipped code
<!-- AC:END -->

## Comments

<!-- COMMENTS:BEGIN -->
created: 2026-08-27 22:17
---
New domain context: on-device sense-making is valuable only inside the supervised pump-track loop, especially for classifying unfamiliar fields and proposing deterministic versus approval-gated actions. Keep the spike explicitly advisory; it must not weaken human approval at irreversible transitions.
---

created: 2026-08-28 18:47
---
Research reconciled and preserved in docs/research/chrome-built-in-ai-flags.md and docs/research/chrome-platform-and-wasm-leverage.md. Verdict: no flags are needed for the core MV3 Prompt/Summarizer path; keep Autofill AI and glic actor flags off during guided dogfooding. The highest-leverage next spike is a local-only chrome.debugger/CDP prototype for selector-free AX/DOMSnapshot capture and ATS response-body evidence. WASM stays a later prototype in an Offscreen Document, SIMD-only; a shared Rust core and IWA/Controlled Frame remain watch items.
---
<!-- COMMENTS:END -->
