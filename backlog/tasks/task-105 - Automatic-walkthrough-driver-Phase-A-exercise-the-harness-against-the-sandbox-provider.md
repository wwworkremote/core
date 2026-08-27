---
id: TASK-105
title: >-
  Automatic walkthrough driver (Phase A: exercise the harness against the
  sandbox provider)
status: To Do
assignee: []
created_date: '2026-08-27 17:25'
labels:
  - architecture
  - sandbox-provider
dependencies:
  - TASK-102
  - TASK-104
documentation:
  - docs/architecture/signature-registry.md
  - docs/architecture/sandbox-provider.md
priority: medium
type: feature
ordinal: 400
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Phase A of the Reference Scenario plan (docs/architecture/signature-registry.md, "Reference Scenario" section): safe, repeatable, automated walkthroughs against the sandbox provider, building and refining the Reference Scenario before any real (Phase B, guided, Mike-driven) run against a live site.

Depends on both the Scenario capture path (TASK-102) and the Greenhouse sandbox provider (TASK-104) existing first -- this is the thing that runs the capture path against the sandbox provider's fake apply flow, repeatably.

Open question from docs/architecture/sandbox-provider.md, not yet decided: drive it with a headless browser (Capybara/Cuprite) hitting the sandbox provider directly, or the real Chrome extension pointed at wwworkremote.localhost under the same env gate as TASK-104? The latter exercises the real extension code path; the former is simpler to automate in CI-style runs. Implementer should pick and document the reasoning, not block on asking.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A walkthrough against the sandbox provider runs end-to-end without manual intervention and produces a real Scenario with ScenarioSignature rows via TASK-102's capture path
- [ ] #2 The resulting Scenario passes Scenarios::HandshakeCheck cleanly for the greenhouse provider (all required kinds present)
- [ ] #3 Documented choice of driver (headless browser vs. real extension) with reasoning, in code comments or a short doc update
<!-- AC:END -->
