---
id: TASK-138
title: >-
  Guided-session light-path screenshot always fails: captureVisibleTab needs
  <all_urls> or activeTab
status: Done
assignee: []
created_date: '2026-08-30 23:37'
updated_date: '2026-08-31 12:55'
labels:
  - extension
  - datalake
  - application-workflow
dependencies: []
references:
  - >-
    backlog/tasks/task-126 -
    Guided-session-raw-asset-capture-into-the-datalake.md
  - docs/architecture/datalake.md
priority: high
type: bug
ordinal: 154000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Found in the first real-browser dogfood of the guided-session capture loop (extension 1.36.0, local /sandbox ATS, 2026-08-30).

In an `application_research` guided session, every viewport screenshot capture fails and is recorded as a manifest gap:

    "reason": "Either the '<all_urls>' or 'activeTab' permission is required."

`content.js` `captureViewportScreenshot` → background `CAPTURE_VISIBLE_TAB` → `chrome.tabs.captureVisibleTab`. Current Chrome requires `<all_urls>` OR an active `activeTab` grant for that API — a specific `host_permissions` entry (which the manifest has for `wwworkremote.localhost` and every ATS domain) is NOT sufficient. The guided-session flow starts from the localhost web UI and the user navigates directly, so the extension action is never invoked and `activeTab` is never granted. Net effect: `application_research` capture is DOM-only in practice; TASK-126 AC#4 ("application_research sessions capture content-script DOM + captureVisibleTab") cannot be met as built.

Note: the `application_execution` path is unaffected — it screenshots via CDP `Page.captureScreenshot` (verified working, 3420x1904 full-page PNG, zero gaps on the first capture).

Repro: create a GuidedSession with purpose application_research against https://wwworkremote.localhost/sandbox/postings/1, open its tracked_source_url in a browser with the unpacked extension, check data/datalake/sessions/<token>/manifest.json — the screenshot entry is a gap.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 application_research guided sessions no longer attempt a viewport screenshot — no per-event permission gap; DOM snapshot is the research-mode capture
- [x] #2 The <all_urls> option was evaluated and rejected (widens passive exposure on every site for a capture the execution path already covers via CDP) — recorded in docs/architecture/datalake.md
- [x] #3 datalake:sandbox_walkthrough + its spec assert the research bundle is dom-only with zero gaps
- [x] #4 docs/architecture/datalake.md capture table + prose updated
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Resolved as **DOM-only for research mode** (Mike's call). `chrome.tabs.captureVisibleTab` needs `<all_urls>` or an `activeTab` grant; the web-UI-launched guided flow grants neither, so a research-mode viewport screenshot could only ever land a manifest gap on every event. Rather than paper over that, `application_research` simply doesn't attempt a screenshot now — the DOM snapshot is the value.

Changes (extension 1.36.0 → 1.36.1):
- `extension/content.js` — `captureGuidedAssets` only runs `captureExecutionArtifacts` for execution sessions; removed `captureViewportScreenshot`. `captureExecutionArtifacts` now records both a `har` and a `screenshot` gap when the debugger is unavailable/detached (was har-only), and dropped its now-unused return value.
- `extension/background.js` — removed the now-dead `CAPTURE_VISIBLE_TAB` handler.
- `app/services/datalake/sandbox_walkthrough.rb` — `LIGHT = %w[dom]`; `lib/tasks/datalake.rake` + `spec/services/datalake/sandbox_walkthrough_spec.rb` assert research bundle = `%w[dom]`, 0 gaps.
- `docs/architecture/datalake.md` — capture table Screenshot cell for research → "—", plus a paragraph explaining the decision and why `<all_urls>` was rejected.

`<all_urls>` rejected: it would widen passive exposure on every site the browser visits, for a screenshot the execution path already gets via CDP `Page.captureScreenshot`. The datalake's whole posture is machine-local + aggressive prune; broadening the extension's ambient reach to fix a nice-to-have in one mode isn't the trade.

67 datalake/guided-session specs green. TASK-126 AC#4 wording updated to match.
<!-- SECTION:FINAL_SUMMARY:END -->
