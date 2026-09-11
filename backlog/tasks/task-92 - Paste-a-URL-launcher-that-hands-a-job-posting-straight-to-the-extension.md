---
id: TASK-92
title: Paste-a-URL launcher that hands a job posting straight to the extension
status: To Do
assignee: []
created_date: '2026-08-26 23:10'
labels: []
dependencies: []
priority: medium
type: feature
ordinal: 107000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Mike wants a fast path to start ingesting a job posting he already has a link to (e.g. from an email or a shared link), without leaving the Rails app to go find and open the Chrome extension manually.

Constraint confirmed with Mike: a webpage cannot force-open a Chrome extension's side panel directly — there's no API for that, only the extension itself can decide to open it. The agreed mechanism is: a form in the app where Mike pastes a URL, submitting it opens that URL in a new browser tab, and the extension's already-installed content script (which already activates on job board pages today) takes it from there. Mike wants the capture/extraction step itself to begin automatically once that tab opens, so he can move straight into applying, rather than requiring a further manual click in the extension UI — whether the extension's current activation behavior already does this or needs a change is an open question for whoever picks this up to verify against the current extension code (extension/content.js) before implementing.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A form is available in the app where Mike can paste a job posting URL and submit it
- [ ] #2 Submitting the form opens that URL in a new browser tab
- [ ] #3 Once the new tab loads, the extension's capture/extraction flow begins without requiring an additional manual step from Mike
- [ ] #4 Submitting an invalid or non-URL value shows a clear error instead of opening a broken tab
<!-- AC:END -->
