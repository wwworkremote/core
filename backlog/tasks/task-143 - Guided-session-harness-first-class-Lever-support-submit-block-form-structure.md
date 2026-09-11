---
id: TASK-143
title: >-
  Guided-session harness: first-class Lever support (submit-block + form
  structure)
status: To Do
assignee: []
created_date: '2026-08-31 21:51'
labels:
  - harness
  - extension
dependencies: []
priority: medium
type: feature
ordinal: 159000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
## Context

Surfaced 2026-08-31 applying to [redacted] (Sr Software Engineer, [redacted] Platform / DSP — Lever, JobPosting #7068 / Lead #191). Mike wanted the harness on a real Lever application; the guided session records fine but the Bounded Agency guarantee does not hold.

## What works on Lever today (provider-agnostic)

- Page-arrival events (`recordGuidedPageArrival`, fires on any URL change with the token params)
- DOM snapshots (research + execution)
- HAR + full-page CDP screenshot (execution mode, `captureExecutionArtifacts`)

## What does NOT work on Lever

- **The submit-block.** `content.js`'s `submit` listener is gated on `e.target.id !== 'application-form'` (the local sandbox's form id — comment at ~line 1044 says "nothing else carries id='application-form'"). Lever's apply form has different markup, so `e.preventDefault()` never fires. **On Lever the harness observes the boundary, it does not gate it** — clicking Submit submits.
- **Form-structure extraction** (`extractApplicationFormStructure`, `recordGuidedPageArrival`) also keys off `#application-form`.
- The Workday-style live field observer (`isWorkdayApplicationPage`, `discoverApplicationFields`, `workday:` key prefix) is Workday-only.
- **No Lever Reference Scenario.** `Scenario.distinct.pluck(:provider)` → `["greenhouse"]` only (9 scenarios, 1 ReferenceScenario). A completed Lever guided session has nothing to auto-compare against (advisory per ADR 009, not a blocker).

## Scope

1. Teach `content.js` to recognize a Lever application form (`jobs.lever.co/<co>/<id>/apply` — plain `<form>`, fields like `input[name="name"]`, `input[name="email"]`, `.application-question` blocks, `.template-btn-submit` / `button[type=submit]`). Generalize the submit-block + structure extraction off the hardcoded `#application-form` to a per-provider selector map.
2. Optionally: capture a Lever Reference Scenario (needs a real or sandbox Lever apply page — the sandbox is Greenhouse-shaped, so this may mean a second sandbox shape or a one-time real capture).
3. Bump `extension/manifest.json` version (minor — new provider capability).

## Not in scope

The Lever *ingestion* adapter already works (Lead #191 captured + promoted from `jobs.lever.co/[redacted]/...`). This is about the *application/guided-session* side only.

## Acceptance

- [ ] A guided session on a real Lever apply page blocks the final submit and records a `submission_attempted` pending event, same as the sandbox
- [ ] The Lever apply form's field structure is captured (value-free) into the timeline
- [ ] `docs/architecture/guided-session-flow.md` + `docs/extension-workflow.md` updated for the multi-provider form-selector model
<!-- SECTION:DESCRIPTION:END -->
