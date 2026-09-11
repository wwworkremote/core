---
id: TASK-108.1
title: Prototype local Chrome CDP snapshot capture
status: In Progress
assignee: []
created_date: '2026-08-28 19:34'
updated_date: '2026-08-28 19:39'
labels:
  - architecture
  - sandbox-provider
  - chrome
  - spike
dependencies: []
references:
  - TASK-108
  - TASK-112
documentation:
  - docs/research/chrome-platform-and-wasm-leverage.md
modified_files:
  - extension/manifest.json
  - extension/background.js
  - extension/devtools-panel.html
  - docs/research/chrome-platform-and-wasm-leverage.md
  - backlog/tasks/task-108.1 - Prototype-local-Chrome-CDP-snapshot-capture.md
parent_task_id: TASK-108
priority: medium
type: spike
ordinal: 120000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Build a local-only, read-only Chrome DevTools prototype that attaches to the inspected sandbox tab through chrome.debugger, captures Accessibility.getFullAXTree and DOMSnapshot.captureSnapshot, summarizes form fields and snapshot dimensions, and detaches. Use the result to validate selector-free recorder evidence before considering driving or network capture.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Prototype is gated to the unpacked local extension build and requires the debugger permission
- [ ] #2 DevTools panel can capture the inspected tab's accessibility tree and DOM snapshot without navigation or mutation
- [ ] #3 Output summarizes accessible form fields and snapshot dimensions without posting content, credentials, or tokens
- [ ] #4 Debugger detaches after capture, including when a CDP command fails
- [x] #5 Prototype verdict and next step are recorded in TASK-108 documentation

## Implementation note

The local unpacked extension now contains the read-only DevTools CDP probe in
`background.js` and `devtools-panel.html`. It is gated by the absence of the
Web Store `update_url`, requires the `debugger` permission, summarizes the
accessibility tree and DOM snapshot, and detaches after every attempt. The
remaining acceptance checkpoint is real Chrome dogfood against the sandbox.
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented the local-only read-only CDP prototype in extension/background.js and extension/devtools-panel.html. Chrome dogfood confirmed the unpacked extension reloads as v1.27.0, exposes the debugger permission, and renders the WWWorkRemote panel against the authenticated wwworkremote.localhost sandbox without page mutation. The capture control did not produce a visible response while the Chrome automation harness held a competing debugger connection, so attachment/detachment behavior remains unverified.
<!-- SECTION:NOTES:END -->

## Comments

<!-- COMMENTS:BEGIN -->
created: 2026-08-28 19:34
---
Implemented the local-only read-only CDP prototype in extension/background.js and extension/devtools-panel.html. The probe attaches to the inspected tab, captures Accessibility.getFullAXTree plus DOMSnapshot.captureSnapshot, returns bounded field/snapshot summaries, and detaches in finally. Extension version is now 1.27.0. Remaining: dogfood against the sandbox and record the verdict.
---

author: Codex
created: 2026-08-28 19:39
---
Dogfood checkpoint: reloaded the real unpacked extension to v1.27.0; Chrome showed the new “Access the page debugger backend” permission; opened the authenticated wwworkremote.localhost page and WWWorkRemote DevTools panel. No navigation, form fill, or submission occurred. The capture result remains unverified because the automation harness was already debugging the same tab and the panel control produced no visible response. Next step: rerun with the competing debugger detached, then verify both success and failure detach paths before considering this spike complete.
---
<!-- COMMENTS:END -->
