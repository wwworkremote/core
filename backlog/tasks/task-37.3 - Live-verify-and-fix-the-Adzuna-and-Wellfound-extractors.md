---
id: TASK-37.3
title: Live-verify and fix the Adzuna and Wellfound extractors
status: Done
assignee: []
created_date: '2026-08-13 17:41'
updated_date: '2026-08-16 17:59'
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
- [x] #1 Adzuna's extraction (title/company/location/salary/description) is checked against at least one real live posting; any broken selector is identified via live DOM inspection (not guessed) and fixed
- [x] #2 Wellfound's extraction is checked and fixed the same way
- [x] #3 A real capture (Lead creation) is completed live for each provider after fixes land
- [x] #4 manifest.json version bumped per the project's semver rule if any extraction behavior changed
- [x] #5 node --check and npm run lint:extension pass on the modified extension files
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Live-verified both extractors in extension/content.js against real postings (browser automation, real DOM inspection -- never guessed):

**Adzuna** (2 postings, different companies): old selectors (`.company`, `[class*="company-name"]`, `.job-description`, `[class*="JobDescription"]`) silently returned null for company and description on every posting -- location/salary only "worked" by accident, since `[class*="location"]`/`[class*="salary"]` happen to substring-match Adzuna's real classes `.ui-location`/`.ui-salary`. Real classes: `.ui-company`, `.ui-location`, `.ui-salary`, `.adp-body` (description). Fixed to use the real classes.

**Wellfound** (2 postings, different companies): old selectors were pure camelCase guesses (`StartupName`, `jobDescription`, etc.) matching nothing in Wellfound's actual Tailwind-only markup -- everything but title returned null. No data-testid/semantic hooks exist for company text, salary, or description, so fixed via the next-most-stable anchors: company via `a[href^="/company/"]` (excluding the empty-text logo-wrapper anchor), location via `a[href^="/location/"]`, salary via structural position (`h1 + ul li:first-child`, confirmed the `<li>` survives empty-but-present when a listing discloses no salary), description via its two-Tailwind-class combination (`.rounded-xl.border-gray-400`) which uniquely matches only that card, not the header card.

Both providers already had JSON-LD present as a fallback tier, which is why this went unnoticed -- confirmed via console logs that the CSS tier itself was returning null before the fix ("CSS: no content matched") and succeeding after ("CSS (Adzuna) -- 781 desc words", "CSS (Wellfound) -- 499 desc words").

Real end-to-end captures completed for both (not just DOM-level spot checks): Lead #26 (Trane Technologies, Adzuna) and Lead #27 (Hazel, Wellfound), both confirmed persisted in the database via `bin/rails runner`.

manifest.json bumped 1.10.1 -> 1.10.2 (patch: bug fix, no new capability). `node --check extension/content.js` and `npm run lint:extension` both clean.
<!-- SECTION:FINAL_SUMMARY:END -->
