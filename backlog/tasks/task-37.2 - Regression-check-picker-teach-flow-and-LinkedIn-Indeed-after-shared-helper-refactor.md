---
id: TASK-37.2
title: >-
  Regression-check picker/teach flow and LinkedIn/Indeed after shared-helper
  refactor
status: Done
assignee: []
created_date: '2026-08-13 17:40'
updated_date: '2026-08-17 00:20'
labels: []
milestone: m-1
dependencies: []
parent_task_id: TASK-37
priority: medium
type: chore
ordinal: 1100
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
This session introduced or changed several extraction helpers shared across providers: `pickAttr`, `pickLabeledValue`, `companyFromTitleSuffix`, `companyFromWorkdayHostname`, `companyFromSmartRecruitersPath`, and `jsonLdMatchesCurrentPage` (a new guard in `Extractor.jsonLd()` that rejects a JSON-LD candidate whose title doesn't match the current page -- added after finding RemoteOK embeds an entire unrelated job feed's JSON-LD on every posting page). Neither the "teach the extractor" element-picker flow (`app/controllers/api/extraction_rules_controller.rb`, `JobBoards::SelectorLearnerAgent`, the picker UI in `content.js`/`sidepanel.js`) nor the LinkedIn/Indeed extractors (fixed in an earlier part of this session, before the shared-helper changes) have been re-verified against the current build.

Read `docs/extension-workflow.md`'s "Teach the Extractor" sequence diagram before starting.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The teach flow is exercised live on at least one provider: clicking the picker button, selecting an element on a real page, and confirming both an ExtractionRule (current value) and an ExtractionRuleObservation (history entry) are created with the expected selector
- [x] #2 A learned rule is confirmed to actually apply on the next extraction of that provider (the taught field shows the taught value, not the original guess)
- [x] #3 LinkedIn is re-verified live against a real posting: title/company/location/salary/employment_type/remote extracted correctly, including via the insight-pill classifier
- [x] #4 Indeed is re-verified live against a real posting
- [x] #5 Any regression found from the shared-helper changes is fixed and covered by a spec or documented live-verification note
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
**Tooling note**: the side panel isn't addressable via browser automation (not a listed tab; `chrome-extension://` URLs are blocked as browser-internal). Criteria #1/#2 (the picker/teach flow) were verified by simulating the side panel's own POST directly against `/api/extraction_rules` with a realistic payload -- this exercises the exact same backend path the picker triggers (SelectorLearnerAgent -> ExtractionRule upsert -> ExtractionRuleObservation log), just without the manual crosshair-click step.

**Criteria #1/#2 (teach flow)**: POSTed a real teach payload for Indeed's "company" field, deliberately pointed at the job-type text ("Full-time") instead of the real company, specifically so the override would be unambiguous. Confirmed both rows: `ExtractionRule#8` (selector refined by the live SelectorLearnerAgent to `div#salaryInfoAndJobType > span.css-1u1g3ig.eu4oa1w0`) and `ExtractionRuleObservation#1344`. Then ran a real live capture on the same posting: the panel showed `Co. - Full-time` instead of the real company, and the persisted Lead's `company_name` was `"-  Full-time"` -- proving `applyLearnedRules()` genuinely overrides the built-in extractor end-to-end, not just at the API-response level. Cleaned up the deliberately-wrong ExtractionRule and test Lead afterward (left the Observation row -- append-only history log by design, per its own model comment).

**Criteria #3 (LinkedIn)**: live-verified on the split-view search-results layout (the common entry point). Found company/location/employment_type/remote all silently null -- LinkedIn renamed its top-card classes to a `job-details-jobs-unified-top-card__*` scheme; the old `.jobs-unified-top-card__*`/`.topcard__*` selectors and the `__job-insight` pill wrapper no longer exist. Fixed: company via `.job-details-jobs-unified-top-card__company-name`, location via `.job-details-jobs-unified-top-card__tertiary-description-container .tvm__text`, pills via bare `<strong>` tags in the top-card container (still classified by content via `classifyInsightPills`, not position, since an unrelated "Actively reviewing applicants" strong sits alongside them). Recaptured: 7 fields (up from 3), company/location/employment_type all correct, remote="Hybrid" confirmed via classifier pill list. `posted_at` is still broken on this layout (not in this task's acceptance criteria; noted but not fixed -- low-value field, would need a fragile nth-of-type selector).

**Criteria #4 (Indeed)**: live-verified on both page shapes (full `/viewjob?jk=` page and the split-view `/jobs?q=...&vjk=` pane). Three real bugs: (1) title's `h1.jobsearch-JobInfoHeader-title` compound selector required the title to literally be an `<h1>` -- true on the full page, but the split-view pane renders the identically-classed title as an `<h2>`, so the bare `h1` fallback silently grabbed the search page's own h1 ("software engineer jobs") instead -- same root-cause class as TASK-47 (different file: the server-side email/API extractor, not fixed here). Also stripped a UI-only " - job post" suffix nested in the split-view title. (2) `.jobsearch-JobInfoHeader-subtitle` (location) no longer exists -- fixed via `[data-testid="job-location"]`. (3) `.attribute_snippet` (salary) no longer exists -- salary/job-type now share one `#salaryInfoAndJobType` container as two hashed-class sibling spans with no way to tell them apart by selector, so classified by content (reused the existing `SALARY_PILL`/`parseSalaryPill` helpers, same pattern as LinkedIn/Greenhouse) instead of position. Recaptured on the split-view page specifically (the one that was broken): title/company/location/salary all correct, CSS tier (not JSON-LD) won, confirmed via console log and the persisted Lead.

**Criteria #5**: all found regressions fixed above; `node --check` and `npm run lint:extension` clean. manifest.json bumped 1.10.2 -> 1.10.4 (two patch bumps, one per provider fixed).
<!-- SECTION:FINAL_SUMMARY:END -->
