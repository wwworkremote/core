---
id: TASK-122
title: 'Wayfinder decision: guided-recorder raw-capture seam for the datalake'
status: Done
assignee:
  - '@claude'
created_date: '2026-08-29 17:23'
updated_date: '2026-08-29 17:40'
labels:
  - 'wayfinder:grilling'
  - application-capture-datalake
  - 'wayfinder-map:doc-7'
dependencies:
  - TASK-121
references:
  - >-
    backlog/docs/wayfinder/doc-7 -
    Wayfinder-map-link-to-application-capture-and-the-datalake.md
  - >-
    backlog/tasks/task-112 -
    Phase-B-guided-application-session-recorder-with-supervised-intent.md
  - extension/content.js
ordinal: 138000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Decision ticket for wayfinder map doc-7 (backlog/docs/wayfinder/doc-7). Grilling type (HITL) — resolve with Mike via the grilling + domain-modeling skills. Blocked on TASK-121 (Chrome MV3 capture capabilities).

## Question

How does the guided-session recorder produce the datalake raw bundle, and does that expand TASK-112 or become a new task?

Decided in the map: greedy per-transition raw assets (DOM, full HAR, screenshots), written to one directory per `GuidedSession#session_token` under a git-ignored repo path with a `manifest.json`, machine-local and never synced. TASK-121 establishes what the extension can technically capture.

Open for this ticket:
- The write path: extension -> API -> local filesystem. The current extension posts events to `/api/v0/...`; a multi-megabyte DOM/HAR bundle is a different shape. Streamed upload? A local companion writer? Does the Rails app write the files, or does the extension write directly via the File System Access API?
- "Meaningful transition" definition — what triggers a snapshot (navigation, step change, pre-submit, DOM mutation threshold)?
- Whether this is new acceptance criteria on TASK-112 (guided recorder, AC#2-5 already open) or a standalone follow-up task that depends on it.
- How the bundle correlates: the map's spine is `session_token` stamped on capture-table rows and the materialized Scenario — confirm the raw bundle keys the same way and nothing else is needed.
- Failure handling: a capture that fails mid-session must not break the guided session (mirror `extension_error_events`).

Output: the seam decision recorded on the map, plus either edited TASK-112 ACs or a new task created.
<!-- SECTION:DESCRIPTION:END -->

## Comments

<!-- COMMENTS:BEGIN -->
author: wayfinder
created: 2026-08-29 17:40
---
RESOLVED (grilling, 1 round). The raw-capture seam:

- **Transport**: extension POSTs one asset at a time to a new `POST /api/v0/guided_sessions/:session_token/datalake_assets` endpoint mirroring the existing events endpoint (`Rails.env.local?` gate, no auth, via the background `API_FETCH` relay). Rails writes the file under `data/datalake/sessions/<session_token>/` and owns `manifest.json` integrity. No new extension permission. Accepted trade-off: the PII-bearing bytes pass through the localhost Rails process (not logged, not in DB) en route to disk -- fine for Mike's own job-search data on his own machine; File System Access API / native-messaging host judged not worth the complexity.
- **Capture trigger**: one capture per emitted `GuidedSessionEvent`. The recorder (TASK-112) already decides what a meaningful transition is; the datalake capture piggybacks on that, bundle and event timeline 1:1, each event carrying a manifest-entry pointer. No parallel heuristic.
- **Fidelity by purpose**: `application_execution` -> `chrome.debugger` + CDP attached at session start, full HAR incl. response bodies (`Network.streamResourceContent`) + full-page screenshot (`Page.captureScreenshot` `captureBeyondViewport`). `application_research` -> content-script DOM (`Element.getHTML`) + `captureVisibleTab` only, no debugger attach, no banner. Mike can override per session. Rationale: the richest training data is in execution sessions; research sessions stay a light touch.
- **Failure handling**: any capture failure (CDP `onDetach` when DevTools opens / user Cancel, `getResponseBody` eviction, POST failure, cross-origin frame, closed shadow root) -> `EXTENSION_ERROR` + a manifest gap entry `{type, step, status: failed, reason}`; never raises into the guided-session flow. `debugger`-sourced captures are individually optional. (Confirmed against TASK-121 findings.)
- **Correlation**: bundle dir keyed by `session_token`; nothing else needed.
- **Task structure**: NEW task, not TASK-112 ACs. TASK-112 keeps its scope (value-free reviewable event timeline). Created **TASK-126 'Guided session raw-asset capture into the datalake'** (depends on TASK-112). Prune job + curation report + the `Datalake::Bundle`/`Extractor` read side are explicitly out of scope for TASK-126 -- sibling work after the datalake ADR lands.

No new decision tickets surfaced. Map updated.
---
<!-- COMMENTS:END -->
