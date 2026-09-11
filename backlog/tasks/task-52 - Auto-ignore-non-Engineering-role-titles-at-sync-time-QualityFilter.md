---
id: TASK-52
title: Auto-ignore non-Engineering role titles at sync time (QualityFilter)
status: Done
assignee: []
created_date: '2026-08-16 15:21'
updated_date: '2026-08-16 15:32'
labels: []
dependencies: []
references:
  - packages/ingestion/app/services/job_boards/quality_filter.rb
  - packages/ingestion/app/services/job_boards/syncer.rb
priority: high
type: feature
ordinal: 58000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
User: "filter out non-Engineering roles (I am not a sales person or UI designer or customer support person)... capture but don't waste processing power on them." Investigated (fork aca3fd9eb676b5cc4): company-exclusion (CompanyResolver) and commute-zone (Geocoding#enforce_commute_zone) already auto-ignore synchronously/near-synchronously, and JobBoards::Syncer#enrich_if_needed already skips JobBoards::AnalysisJob (Categorizer + Embedder, the expensive LLM/embedding step) for any job_posting.ignored? at save time -- the guard architecture the user is asking for already exists for those two cases. The gap: no equivalent exists for role/title relevance. JobBoards::QualityFilter#useful? (packages/ingestion/app/services/job_boards/quality_filter.rb) already runs synchronously in Syncer#prepare_posting before save, with an established BANNED_TITLES/BANNED_KEYWORDS literal-match pattern -- the natural, lowest-risk place to add this, not new architecture.

Scope: title-based keyword matching only (mirrors existing BANNED_TITLES precedent -- "a lookup table, not an ML classifier"), NOT LLM-based classification (that's the exact cost this is trying to avoid paying on irrelevant postings). Will miss ambiguous titles; that's an accepted tradeoff at this layer, not a defect.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 QualityFilter#useful? returns false for postings whose title matches an obvious non-Engineering role keyword (sales, account executive, customer support/success, UI/UX/graphic designer, marketing)
- [x] #2 The excluded posting is still ingested as a JobPosting row (status: ignored), not dropped from the data lake entirely -- matches the existing company-exclusion behavior, not a hard delete
- [x] #3 JobBoards::AnalysisJob (Categorizer + Embedder) is confirmed to never enqueue for a posting excluded this way, via the existing enrich_if_needed guard -- verified with a spec, not assumed
- [x] #4 New JobBoards::QualityFilter spec file covers both pre-existing behavior (banned titles, country mismatch, short body) and the new role-keyword check -- this class had zero prior spec coverage
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added `NON_ENGINEERING_TITLE_KEYWORDS` + `ENGINEERING_ADJACENT_EXCEPTIONS` to `JobBoards::QualityFilter`, checked in `useful?` alongside the existing banned-title/country/body-length checks (same synchronous, pre-save call site in `Syncer#prepare_posting` -- no new architecture).

First pass used narrow phrases ("Account Executive", "Sales Manager", etc.) -- live-verified against real dev data and found it missed common real titles ("Loan Sales Specialist", "Sales Associate"). Broadened to bare-word "Sales"/"Marketing" matching, with an explicit exception list ("Sales Engineer", "Solutions Engineer", etc.) protecting genuinely technical hybrid roles. Re-verified: 15/15 real non-Engineering dev postings now correctly filtered (was 1/15 before broadening), a real "Senior Software Engineer (Ruby on Rails)" posting still passes.

AC #3 verified with a real integration spec in syncer_spec.rb (not assumed): a document with a rejected title is synced through the actual Syncer, asserting the resulting JobPosting is `status: "ignored"` AND `JobBoards::AnalysisJob` is enqueued exactly 0 times in that block.

New quality_filter_spec.rb (28 examples) covers every existing untested branch (blank/banned/short title, country mismatch, blank country_code bypass, short body) plus the new role check, parameterized over the actual `NON_ENGINEERING_TITLE_KEYWORDS` constant so the list and its test coverage can't drift apart.

Verified: full pre-commit-equivalent suite (`rspec spec packages/ingestion/spec`) -- 717 examples, 0 failures. RuboCop clean.

Found but deliberately NOT touched: `QualityFilter::BANNED_KEYWORDS` (visa/citizenship phrases) is defined but never referenced anywhere in the class -- dead code. Left alone since enabling it would encode an assumption about the user's own citizenship/visa status that hasn't been confirmed; flagged to the user rather than guessed at.
<!-- SECTION:FINAL_SUMMARY:END -->
