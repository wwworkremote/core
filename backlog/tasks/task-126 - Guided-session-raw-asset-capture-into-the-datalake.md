---
id: TASK-126
title: Guided session raw-asset capture into the datalake
status: To Do
assignee: []
created_date: '2026-08-29 17:40'
updated_date: '2026-08-29 17:40'
labels:
  - application-workflow
  - extension
  - datalake
  - human-in-the-loop
dependencies:
  - TASK-112
references:
  - >-
    backlog/docs/wayfinder/doc-7 -
    Wayfinder-map-link-to-application-capture-and-the-datalake.md
  - >-
    backlog/tasks/task-122 -
    Wayfinder-decision-guided-recorder-raw-capture-seam-for-the-datalake.md
  - docs/research/mv3-capture-capabilities.md
  - >-
    backlog/tasks/task-123 -
    Wayfinder-decision-datalake-to-operational-read-model-contract.md
priority: medium
type: feature
ordinal: 142000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implementation task from wayfinder map doc-7 (backlog/docs/wayfinder/doc-7), seam decided in TASK-122. Depends on TASK-112's guided-session event stream. Capture per-transition raw assets (DOM, HAR, screenshots) from a guided session into a machine-local datalake bundle so later extraction (question graph, trace evidence, topology) has raw material to pull from.

DECIDED (do not re-litigate):

- Transport: extension POSTs one asset at a time to a new `POST /api/v0/guided_sessions/:session_token/datalake_assets` endpoint (mirrors the existing events endpoint -- `Rails.env.local?` gate, `skip_before_action :authenticate_admin` / `:verify_authenticity_token`, via the background `API_FETCH` relay). Rails writes the file under `data/datalake/sessions/<session_token>/` and appends/updates that dir's `manifest.json`. Rails owns manifest integrity. No new extension permission (extension already holds `activeTab` + `debugger` + host list).
- Capture trigger: one capture per emitted `GuidedSessionEvent` (page_arrived, application_page_arrived, step changes, submission_attempted). The bundle and the event timeline align 1:1; each `GuidedSessionEvent` carries a pointer to its manifest entry/entries. No separate 'meaningful transition' heuristic.
- Fidelity by purpose: `application_execution` sessions attach `chrome.debugger` + CDP at session start and capture full HAR incl. response bodies (prefer `Network.streamResourceContent` to beat buffer eviction) + a full-page screenshot (`Page.captureScreenshot` `captureBeyondViewport:true`, clip from `Page.getLayoutMetrics`). `application_research` sessions capture content-script DOM + `chrome.tabs.captureVisibleTab` (viewport only) -- no debugger attach, no banner. Mike can override per session.
- DOM: content-script `documentElement.getHTML({ serializableShadowRoots: true, shadowRoots: [<collected open roots>] })` per injected frame, stitched by frame id. Cross-origin frames and closed shadow roots are gaps, not failures.
- Failure handling: any capture failure (CDP `onDetach` from DevTools opening / user Cancel, `getResponseBody` eviction, POST failure, cross-origin frame, closed shadow root) emits an `EXTENSION_ERROR` and writes a manifest gap entry `{ type, step, status: "failed", reason }`. Never raises into the guided-session flow. `debugger`-sourced captures are individually optional and degrade cleanly.
- Correlation: the bundle dir is keyed by `GuidedSession#session_token` -- nothing else needed (the map's spine).

Manifest entry per asset: type, step (the `GuidedSessionEvent` id), sha256, captured_at, byte size; gap entries add the failure reason. Concrete manifest schema is for this task to finalise.

OUT OF SCOPE for this task (sibling work, after the datalake ADR lands): the prune job + curation report (map 'Curation gate' decision); the `Datalake::Bundle` / `Datalake::Extractor` read side (TASK-123 contract); closed-shadow-DOM capture (needs a `document_start` MAIN-world `attachShadow` shim -- separate task per TASK-121).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 POST /api/v0/guided_sessions/:session_token/datalake_assets accepts one asset (DOM snapshot | screenshot | har | dom-styles), writes it under data/datalake/sessions/<session_token>/, and appends a manifest.json entry; gated on Rails.env.local?, no auth, mirrors the events endpoint
- [ ] #2 /data/datalake/ is added to .gitignore and the directory is never committed or synced
- [ ] #3 During a guided session the extension captures one asset set per emitted GuidedSessionEvent and each GuidedSessionEvent records a pointer to its manifest entry/entries
- [ ] #4 application_execution sessions attach chrome.debugger at session start and capture full HAR including response bodies + a full-page screenshot per transition; application_research sessions capture content-script DOM + captureVisibleTab only with no debugger attach
- [ ] #5 A capture failure (onDetach, body eviction, POST failure, cross-origin frame, closed shadow root) emits an EXTENSION_ERROR and writes a manifest gap entry {type, step, status: failed, reason} and never raises into the guided-session flow
- [ ] #6 manifest.json records per asset: type, step (GuidedSessionEvent id), sha256, captured_at, byte size; gap entries add reason
- [ ] #7 If chrome.debugger onDetach fires mid-session, remaining transitions are marked partially-captured in the manifest and the session completes normally
- [ ] #8 Focused specs plus a sandbox walkthrough prove a completed application_execution session produces a bundle dir + manifest with the expected asset types, and an application_research session produces the lighter set with no debugger banner
- [ ] #9 The seam is documented in the datalake architecture doc / ADR that wayfinder map doc-7 produces
<!-- AC:END -->
