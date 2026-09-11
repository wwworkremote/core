---
id: TASK-134
title: >-
  Datalake capture: chrome.debugger HAR bodies + full-page screenshots for
  application_execution
status: Done
assignee: []
created_date: '2026-08-30 18:44'
updated_date: '2026-08-30 21:46'
labels:
  - application-capture-datalake
  - 'wayfinder-map:doc-7'
  - extension
dependencies:
  - TASK-126
references:
  - docs/research/mv3-capture-capabilities.md
  - extension/background.js
  - app/controllers/api/datalake_assets_controller.rb
  - >-
    backlog/tasks/task-126 -
    Guided-session-raw-asset-capture-into-the-datalake.md
priority: medium
type: feature
ordinal: 150000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The heavy-fidelity half of TASK-126 AC#4. TASK-126 built the light path (content-script DOM + viewport screenshot per GuidedSessionEvent) and the Rails write side (`POST /api/guided_sessions/:token/datalake_assets`, `Datalake::AssetStore`, manifest, gap entries, event pointers). This adds, for `application_execution` sessions only:

- Attach `chrome.debugger` + CDP at guided-session start; `Network.enable`.
- Per emitted `GuidedSessionEvent`, POST a HAR-shaped `har` asset with response bodies (prefer `Network.streamResourceContent` to beat buffer eviction; `Network.getResponseBody` fallback).
- Per event, a full-page `screenshot` via `Page.captureScreenshot` `captureBeyondViewport: true` with a clip from `Page.getLayoutMetrics` (replaces the viewport screenshot for execution sessions).
- `onDetach` (DevTools opened, or user cancelled the banner) → mark remaining transitions as `har` / `screenshot` gaps and continue on the light path.
- The session's `purpose` reaches content.js — add `guided_session_purpose` to `GuidedSession#tracked_source_url`, or content.js fetches it.
- `manifest.json` version bump.

## Why separate
The `chrome.debugger` attach shows a persistent per-tab banner, dies when DevTools opens, and its behaviour against a live employer site genuinely needs a real dogfood pass. TASK-121's research (`docs/research/mv3-capture-capabilities.md` §5-7) is the reference.

## Out of scope
- Closed-shadow-DOM capture (needs a document_start MAIN-world attachShadow shim — separate).
- The prune job / curation report (still a TASK-126 follow-up).
- `Datalake::Bundle` read side (TASK-123 contract).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 application_execution sessions attach chrome.debugger at session start and, per GuidedSessionEvent, capture a HAR asset with response bodies + a full-page screenshot; application_research keeps the light path
- [x] #2 chrome.debugger onDetach mid-session marks remaining transitions as har/screenshot gaps in manifest.json and the session completes normally on the light path
- [x] #3 The session purpose reaches content.js (tracked_source_url param or a fetch)
- [x] #4 A sandbox walkthrough shows an application_execution bundle with har + full-page screenshot asset types and an application_research bundle with the lighter set (no debugger banner)
- [x] #5 extension/manifest.json version bumped; rubocop + brakeman clean
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Merged to main (`b916b13a`, branch `task-134-datalake-debugger`, 4 commits). Full suite 1126/0; rubocop + brakeman + eslint clean. No Rails schema change — `har` / `screenshot` were already in `Datalake::AssetStore::TYPES`.

**AC#3 — purpose reaches content.js.** `GuidedSession#tracked_query` carries `guided_session_purpose` alongside the token; `content.js` reads `urlParams.get('guided_session_purpose')` → `isGuidedExecution`.

**AC#1 — the debugger path.** `background.js`:
- `guidedDebuggerAttach(tabId)` — `chrome.debugger.attach` `1.3`, `Network.enable` (enlarged buffers), `Page.enable`. Sent by `content.js` at session start for execution sessions, and again before every capture (idempotent — covers a service-worker restart).
- `chrome.debugger.onEvent` buffers `requestWillBeSent` / `responseReceived` / `loadingFinished` / `loadingFailed` per `requestId` in an in-memory `Map`.
- `guidedExecutionCapture` per `GuidedSessionEvent` → `buildHar` (HAR 1.2, response bodies via `Network.getResponseBody`, caps `MAX_HAR_ENTRIES` 60 / `MAX_BODY_BYTES` 512 KB, per-entry `_bodyError` on eviction) + `fullPageScreenshot` (`Page.getLayoutMetrics` → `cssContentSize` clip → `Page.captureScreenshot` `captureBeyondViewport: true`). Buffer cleared after each capture.
- `content.js` `captureGuidedAssets`: DOM snapshot always, then for execution sessions `captureExecutionArtifacts` POSTs the `har` + full-page `screenshot`; `application_research` keeps the content-script DOM + `captureVisibleTab` viewport path untouched.

**AC#2 — onDetach.** `chrome.debugger.onDetach` sets a per-tab flag; subsequent `guidedExecutionCapture` returns `{ detached, reason }`; `content.js` writes `har` + `screenshot` gaps for that transition and continues — the DOM light path still lands and the session completes normally. `tabs.onRemoved` detaches + clears state.

**AC#4 — sandbox walkthrough.** `Datalake::SandboxWalkthrough` now returns `{ execution:, research: }`. Execution bundle: `asset_types == %w[dom har screenshot]` + one simulated detach gap. Research bundle: `asset_types == %w[dom screenshot]`, zero gaps, no debugger. `rake datalake:sandbox_walkthrough` asserts both; `spec/services/datalake/sandbox_walkthrough_spec.rb` covers both. `Datalake::AssetStore#summary` added for the bundle shape.

**AC#5.** `extension/manifest.json` 1.35.0 → 1.36.0 (minor — new `GUIDED_DEBUGGER_ATTACH` / `GUIDED_EXECUTION_CAPTURE` message types). rubocop + brakeman clean.

**Needs a browser dogfood** (the task calls this out explicitly): the `chrome.debugger` banner, HAR body-eviction rate under `getResponseBody`, full-page clip correctness against a live ATS, and onDetach mid-session all need a real run with Mike's Chrome + extension 1.36.0.

**Known ceilings carried forward** (documented in `docs/architecture/datalake.md`): `getResponseBody` not `streamResourceContent` (evicted bodies → `_bodyError`); closed shadow roots + cross-origin frames still uncaptured (needs a `document_start` MAIN-world shim — separate task if a target ATS needs it); `guidedDebugger` state is in-memory so an MV3 worker kill drops the attach until `content.js` re-attaches (banner re-shows once).
<!-- SECTION:FINAL_SUMMARY:END -->
