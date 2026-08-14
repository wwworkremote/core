---
id: TASK-37.3
title: Live-verify and fix the Adzuna and Wellfound extractors
status: To Do
assignee: []
created_date: '2026-08-13 17:41'
labels: []
milestone: m-1
dependencies: []
parent_task_id: TASK-37
priority: medium
type: bug
ordinal: 1200
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Adzuna and Wellfound are the only two currently-supported providers (of 12 in `extension/content.js`'s `PROVIDERS` object) whose extractors have never been checked against a real live posting -- their CSS selectors are original guesses that predate this session's fidelity-audit work. Every other provider had at least one real, live-verified bug (see the parent task and `docs/extension-workflow.md` for the pattern: hashed CSS classes silently pointing at the wrong element, full site redesigns, JSON-LD feed contamination). There's no reason to assume these two are any more reliable -- they just haven't been checked yet.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Adzuna's extraction (title/company/location/salary/description) is checked against at least one real live posting; any broken selector is identified via live DOM inspection (not guessed) and fixed
- [ ] #2 Wellfound's extraction is checked and fixed the same way
- [ ] #3 A real capture (Lead creation) is completed live for each provider after fixes land
- [ ] #4 manifest.json version bumped per the project's semver rule if any extraction behavior changed
- [ ] #5 node --check and npm run lint:extension pass on the modified extension files
<!-- AC:END -->
