---
id: TASK-138
title: >-
  Guided-session light-path screenshot always fails: captureVisibleTab needs
  <all_urls> or activeTab
status: To Do
assignee: []
created_date: '2026-08-30 23:37'
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
- [ ] #1 An application_research guided session captures a viewport (or full-page) screenshot per event with no permission gap, without requiring the user to click the extension icon first
- [ ] #2 The chosen fix is evaluated against the privacy cost of <all_urls> (the datalake doc's posture is machine-local + aggressive prune, but <all_urls> widens passive exposure on every site)
- [ ] #3 A focused test or a documented manual dogfood step proves the screenshot lands
- [ ] #4 docs/architecture/datalake.md capture table updated if the research-mode screenshot mechanism changes
<!-- AC:END -->
