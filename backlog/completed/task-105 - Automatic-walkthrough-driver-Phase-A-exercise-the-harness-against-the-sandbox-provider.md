---
id: TASK-105
title: >-
  Automatic walkthrough driver (Phase A: exercise the harness against the
  sandbox provider)
status: Done
assignee:
  - mike
created_date: '2026-08-27 17:25'
updated_date: '2026-08-27 21:55'
labels:
  - architecture
  - sandbox-provider
dependencies:
  - TASK-102
  - TASK-104
documentation:
  - docs/architecture/signature-registry.md
  - docs/architecture/sandbox-provider.md
modified_files:
  - extension/manifest.json
  - extension/content.js
  - app/controllers/api/scenarios_controller.rb
  - app/services/scenarios/capture.rb
  - config/routes.rb
  - spec/requests/api/scenarios_spec.rb
  - spec/services/scenarios/capture_spec.rb
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

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Use the real unpacked Chrome extension as the Phase A walkthrough driver, pointed at the environment-gated `wwworkremote.localhost` sandbox.
2. Verify the local Rails app and extension are running in a local-build configuration where `IS_LOCAL_BUILD` recognizes `wwworkremote.localhost` as Greenhouse.
3. Open the sandbox posting in Chrome, exercise the extension's actual Greenhouse extraction/capture path, and submit the fake application through the real form without manual intervention beyond the driver actions.
4. Collect the resulting HAR/DOM evidence from the browser run and pass it through `Scenarios::Capture` to persist a real Scenario and ScenarioSignature rows.
5. Run `Scenarios::HandshakeCheck` against that Scenario and assert the greenhouse required signatures are present.
6. Document the driver choice in the architecture docs or walkthrough code: the real extension gives durable end-to-end coverage of provider recognition, extraction, form handling, and capture; direct Cuprite remains a lower-level fallback for deterministic fixture tests.
7. Verify the focused walkthrough/capture/handshake checks and inspect the final diff for unrelated changes before committing.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Preparation complete: reviewed TASK-105 acceptance criteria, signature-registry/sandbox-provider architecture docs, Scenarios::Capture and HandshakeCheck, sandbox routes/controllers/views/specs, extension selectors, and existing Cuprite configuration. No code changes made yet.

User-directed design decision: dogfood the real Chrome extension against wwworkremote.localhost under TASK-104's local-build gate. Replaced the earlier Cuprite-direct proposal before implementation.

Live dogfood update: Chrome confirms the unpacked extension is loaded from repository extension/ at version 1.26.0 and enabled. Sandbox page renders in Chrome, but the capture overlay did not appear after extension reload; manifest now covers both HTTP/HTTPS wwworkremote.localhost and runtime recognition remains gated by IS_LOCAL_BUILD plus exact hostname. Focused Rails/API/capture/sandbox specs pass: 16 examples, 0 failures. Next investigation is Chrome content-script injection/runtime visibility before declaring TASK-105 complete.

Follow-up live run with authenticated Chrome: Chrome reports the unpacked extension loaded from the repository and enabled; sandbox page is rendered, but content.js still does not inject (no capture overlay, no new extension runtime error, no Scenario row). The new local-only scenario_walkthrough=1 mode is implemented but cannot run until Chrome injection is resolved. Backend focused checks remain green: 16 examples, 0 failures.
<!-- SECTION:NOTES:END -->

## Comments

<!-- COMMENTS:BEGIN -->
author: Codex
created: 2026-08-27 21:23
---
Prepared for implementation. Proposed driver: direct Capybara/Cuprite against the Rails sandbox, chosen for deterministic CI-style execution; the walkthrough seam should remain narrow enough to swap in a real-extension adapter later.
---

author: Codex
created: 2026-08-27 21:27
---
Driver decision finalized by user: use the real Chrome extension pointed at wwworkremote.localhost. This exercises provider recognition, extraction, form handling, and capture as one durable process.
---

author: Codex
created: 2026-08-27 21:33
---
User confirmed the ADR is the decision made in this chat: use the real installed/logged-in Chrome extension against wwworkremote.localhost. No separate third-party extension is required.
---

author: Codex
created: 2026-08-27 21:34
---
Live run is blocked at Chrome content-script injection, not Rails or Scenario persistence. The extension is installed from the expected repository path and enabled; no new runtime errors appeared.
---
<!-- COMMENTS:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented and dogfooded the Phase A Chrome walkthrough against https://wwworkremote.localhost. The unpacked extension now matches the secure sandbox origin, opt-in scenario walkthrough captures the posting and confirmation DOM through a local-only API endpoint, persists both Greenhouse signatures, and reports a passing live HandshakeCheck. Focused suite: 22 examples, 0 failures. Commit: 735c72e6.
<!-- SECTION:FINAL_SUMMARY:END -->
