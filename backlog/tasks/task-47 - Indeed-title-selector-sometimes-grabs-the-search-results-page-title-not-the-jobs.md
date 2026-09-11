---
id: TASK-47
title: >-
  Indeed title selector sometimes grabs the search-results-page title, not the
  job's
status: To Do
assignee: []
created_date: '2026-08-16 02:44'
labels:
  - extraction
  - data-quality
dependencies: []
references:
  - >-
    packages/ingestion/app/services/job_fetchers/canonical_job_extractor/selectors.rb
  - TASK-26
priority: medium
type: bug
ordinal: 53000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TASK-26 (Done) flagged this explicitly in its own description as "worth fixing alongside" the interstitial-detection work, but the implementation notes only cover the interstitial guard -- this half was never actually done.

Caught live during this session's TASK-19 email-pipeline verification: a real Indeed-email-sourced JobPosting was created with title "ruby jobs in Remote" (JobPosting #5475, now ignored) whose `target_url` was `https://www.indeed.com/jobs?q=ruby&hl=en&from=ja&l=Remote&...` -- an Indeed *search results* page URL, not an individual `/viewjob?jk=...` posting URL. Oddly, `company` ("Bold Penguin, Inc.") and `body` (a real, coherent job description) were both populated correctly -- only `title` picked up the search page's own `<title>`/`<h1>` text instead of the specific job's.

Current selectors (packages/ingestion/app/services/job_fetchers/canonical_job_extractor/selectors.rb): `"indeed" => { title: ["h1.jobsearch-JobInfoHeader-title", "h1"], ... }` -- the bare `"h1"` fallback is too greedy and will happily match a search-results page's h1 when the specific selector doesn't hit, same root-cause class as this session's Workday `mergeNonNull` blank-string-clobber bug (a lower-priority fallback masking that the higher-priority signal wasn't actually what was expected).

Also worth checking: why did `company`/`body` extraction succeed with real per-job content on what looks like a search-results URL at the HTTP level -- possibly the URL itself redirected server-side to a real job page but title extraction ran against stale/cached content, or Indeed's search page happens to inline one real job's full description server-side (an SEO/preview pattern). Needs a live re-check against a real captured Indeed search-results-page HTML sample (this codebase's established discipline: never trust a selector without live-checking it first) before changing the selector blindly.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Live-fetch a real Indeed search-results-page URL (not a /viewjob?jk= URL) and inspect its actual DOM to understand why company/body extraction succeeded while title did not
- [ ] #2 Tighten the Indeed title selector (or add a URL-shape guard) so a search-results page can't be mistaken for an individual job posting
- [ ] #3 Confirm the fix doesn't regress the existing passing Indeed contract spec case
- [ ] #4 Spot-check for other pre-existing JobPosting rows with target_url matching indeed.com/jobs?q= (search page pattern) rather than /viewjob or /rc/clk (real posting patterns) and decide whether to bulk-ignore them
<!-- AC:END -->
