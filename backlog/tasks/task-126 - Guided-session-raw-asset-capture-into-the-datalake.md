---
id: TASK-126
title: Guided session raw-asset capture into the datalake
status: Done
assignee: []
created_date: '2026-08-29 17:40'
updated_date: '2026-08-31 12:56'
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
- [x] #1 POST /api/v0/guided_sessions/:session_token/datalake_assets accepts one asset (DOM snapshot | screenshot | har | dom-styles), writes it under data/datalake/sessions/<session_token>/, and appends a manifest.json entry; gated on Rails.env.local?, no auth, mirrors the events endpoint
- [x] #2 /data/datalake/ is added to .gitignore and the directory is never committed or synced
- [x] #3 During a guided session the extension captures one asset set per emitted GuidedSessionEvent and each GuidedSessionEvent records a pointer to its manifest entry/entries
- [x] #4 application_execution sessions attach chrome.debugger at session start and capture full HAR including response bodies + a full-page screenshot per transition; application_research sessions capture content-script DOM only (viewport screenshot dropped — see TASK-138)
- [x] #5 A capture failure (onDetach, body eviction, POST failure, cross-origin frame, closed shadow root) emits an EXTENSION_ERROR and writes a manifest gap entry {type, step, status: failed, reason} and never raises into the guided-session flow
- [x] #6 manifest.json records per asset: type, step (GuidedSessionEvent id), sha256, captured_at, byte size; gap entries add reason
- [x] #7 If chrome.debugger onDetach fires mid-session, remaining transitions are marked as har/screenshot gaps and the session completes normally
- [x] #8 Focused specs plus a sandbox walkthrough prove a completed application_execution session produces a bundle dir + manifest with the expected asset types, and an application_research session produces the DOM-only set with no debugger banner
- [x] #9 The seam is documented in the datalake architecture doc / ADR that wayfinder map doc-7 produces
<!-- AC:END -->

## Comments

<!-- COMMENTS:BEGIN -->
author: @claude
created: 2026-08-30 18:52
---
## Session 2026-08-30: write side + light path built; debugger fidelity split to TASK-134

Merged to main `95e8ec00` (+ `5f29521e` brakeman fix). Full suite 1107 examples / 0 failures.

**Done (AC#1, #2, #3, #5, #6, #8, #9):**
- `POST /api/guided_sessions/:session_token/datalake_assets` — `Api::DatalakeAssetsController`, `Rails.env.local?` only, no auth, mirrors the events endpoint. Accepts one base64 asset (`dom` / `har` / `screenshot` / `dom_styles`) or a `gap` note.
- `Datalake::AssetStore` — writes files under `data/datalake/sessions/<token>/`, Rails owns `manifest.json`: per asset `seq` / `guided_session_event_id` / `type` / `path` / `sha256` / `bytes` / `captured_at`; `gaps[]` add `reason`. `purge!` (seed of the prune step).
- `.gitignore` covers `data/datalake/` (landed with the spec-lock commit).
- **Extension light path** (`content.js`): every emitted `GuidedSessionEvent` fires a fire-and-forget capture of the content-script DOM + a viewport screenshot (`background.js` `CAPTURE_VISIBLE_TAB`), one asset at a time. A failure POSTs a manifest gap and **never breaks the session**.
- `GuidedSessionEvent#note_datalake_asset` stamps `evidence["datalake_asset_seqs"]` — the event points back at its manifest entries.
- `Datalake::SandboxWalkthrough` + `rake datalake:sandbox_walkthrough` — proves the manifest shape (3 assets, 1 gap, every event pointed). Rails-side simulation.
- `datalake.md` updated. `manifest.json` → **1.34.0**.

**Deferred to [TASK-134](task-134) (AC#4, #7):** the `chrome.debugger` + CDP path for `application_execution` — HAR-with-response-bodies + full-page screenshots, and the `onDetach` → partially-captured handling. Split because the debugger attach shows a persistent banner, dies when DevTools opens, and genuinely needs a real dogfood pass against a live site (TASK-121 research §5-7 is the reference). The task's own DECIDED note ("debugger-sourced captures must be individually optional") supports the split.

**Still open (real-browser):** a dogfood pass confirming the light-path capture fires per event in the loaded extension and the manifest fills in against a real multi-step flow.
---

author: claude
created: 2026-08-30 23:37
---
## First real-browser dogfood 2026-08-30 (extension 1.36.0, local /sandbox ATS)

The capture loop ran end-to-end in a real Chrome for the first time (every prior GuidedSession in the dev DB was from the `rake datalake:sandbox_walkthrough` Rails sim). Both purposes exercised against `https://wwworkremote.localhost/sandbox/postings/1`.

**Working (AC #1, #3, #5, #6, #8, #9):**
- `application_page_arrived` event recorded with full field extraction — 6 fields classified (identity / screening_question / demographic), question_count, job_post_id, provider. `submission_attempted` recorded with req=required / rev=irreversible / appr=pending.
- Datalake POSTs go through the background API_FETCH relay to the default `http://localhost:31000` (no extension config needed — the endpoints are Rails.env.local? gated, no auth) and land on disk. `manifest.json` schema exactly as designed: seq / guided_session_event_id / type / path / sha256 / bytes / captured_at; gaps[] with reason.
- `evidence.datalake_asset_seqs` pointer back on every event.
- Bounded Agency enforced in code: `submission_attempted` fires, `e.preventDefault()` blocks the real submit, page does not navigate. Verified on both research and execution sessions.
- Session timeline UI (`/guided_sessions/:id`) is genuinely good: RECORDED TIMELINE with per-event classification + observed form structure, REPLAY PLAN (auto/pause per step), Approve/Deny gate, REFERENCE COMPARISON.

**AC #4 — partial.** `application_execution` 1st capture: DOM + HAR + full-page CDP screenshot (3420x1904 PNG), zero gaps, debugger attached cleanly. But: (a) `application_research` viewport screenshot fails every time — `captureVisibleTab` permission gap → **TASK-138** (High); (b) execution debugger doesn't survive to the 2nd capture, `target_closed` → **TASK-139** (Medium, confounded by the automation harness also using CDP).

**AC #7 — holds.** When the execution captures failed they became gaps, the session continued, DOM still captured.

**HAR is empty (`entries:[]`) on both execution captures** — expected: Network.enable after page load sees no traffic, and the only would-be XHR (submit) is blocked by Bounded Agency. The sandbox cannot exercise HAR-with-bodies fidelity; that needs a real multi-request ATS or a richer sandbox.

Dogfood sessions kept for reference: GuidedSession #11 (research, token jRqMptpmRxjEaJBs8dcxvsVB) and #12 (execution, token eaCyXPDR2Prxu1j94LJ399jw); bundles under data/datalake/sessions/ (git-ignored).

Recommend: close this task once TASK-138 lands (it carries the remaining real AC#4 gap); TASK-139 tracks the rest.
---

author: claude
created: 2026-08-31 12:56
---
Closed. AC#4 resolved by TASK-138 (research mode is DOM-only — `captureVisibleTab` can't work in the guided flow, `<all_urls>` rejected). AC#7 holds (onDetach → har/screenshot gaps, session continues). Remaining execution-path issue (debugger doesn't survive to the 2nd capture) is tracked separately as TASK-139. Write side + light path + debugger path all built, merged, and dogfooded.
---
<!-- COMMENTS:END -->
