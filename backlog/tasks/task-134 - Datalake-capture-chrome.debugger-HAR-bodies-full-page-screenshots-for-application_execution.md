---
id: TASK-134
title: >-
  Datalake capture: chrome.debugger HAR bodies + full-page screenshots for
  application_execution
status: To Do
assignee: []
created_date: '2026-08-30 18:44'
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
- [ ] #1 application_execution sessions attach chrome.debugger at session start and, per GuidedSessionEvent, capture a HAR asset with response bodies + a full-page screenshot; application_research keeps the light path
- [ ] #2 chrome.debugger onDetach mid-session marks remaining transitions as har/screenshot gaps in manifest.json and the session completes normally on the light path
- [ ] #3 The session purpose reaches content.js (tracked_source_url param or a fetch)
- [ ] #4 A sandbox walkthrough shows an application_execution bundle with har + full-page screenshot asset types and an application_research bundle with the lighter set (no debugger banner)
- [ ] #5 extension/manifest.json version bumped; rubocop + brakeman clean
<!-- AC:END -->
