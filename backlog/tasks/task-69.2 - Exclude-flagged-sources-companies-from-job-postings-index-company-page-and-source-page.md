---
id: TASK-69.2
title: >-
  Exclude flagged sources/companies from job postings index, company page, and
  source page
status: Done
assignee: []
created_date: '2026-08-19 01:58'
updated_date: '2026-08-19 02:23'
labels: []
dependencies:
  - TASK-69.1
modified_files:
  - packages/ingestion/app/services/job_boards/quality_filter.rb
  - app/controllers/admin/sources_controller.rb
  - spec/requests/admin/sources_spec.rb
  - packages/ingestion/spec/services/job_boards/quality_filter_spec.rb
parent_task_id: TASK-69
priority: high
type: feature
ordinal: 80000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Once TASK-69.1 lands the results-exclusion flag on `JobBoards::Source`, apply it as a default scope/exclusion everywhere job postings are listed: `JobPostingsController#index`, `CompaniesController#show`, and the source-scoped view (`job_postings_path(source_id: ...)` per `app/views/job_postings/index.html.erb:177`). Also add the equivalent "exclude everything from this source/company" bulk action already patterned by `Admin::CompaniesController#mark_not_interested` (`app/controllers/admin/companies_controller.rb:17-29`) — but as results-exclusion (not ingestion-disable, not purge) for the source case, mirroring what TASK-69.1 built.

Once this ships, flip ArbeitNow's flag on `/admin/sources/17` as the immediate real-world trigger case.
<!-- SECTION:DESCRIPTION:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Turned out much smaller than scoped: instead of adding `where.not` scopes to every job-posting-listing controller (index/company/source), reused the exact mechanism the codebase already has for `Company#ingestion_enabled` -- auto-`ignore` at the QualityFilter/Auditor layer, which every listing already excludes by status. Zero changes needed to JobPostingsController, CompaniesController, or any view.

- `JobBoards::QualityFilter#excluded_source?` now returns false (unusable) when a posting's source resolves to a `JobBoards::Source` flagged `excluded_from_results`. This gates both the sync-time path (new postings from a flagged source self-ignore going forward) and the existing `JobBoards::Auditor#audit_low_quality` sweep (already-ingested postings get caught the next time "Run Audit" runs).
- Found and had to route around a real modeling gotcha: `JobPosting#source` (raw `Source`) `.origin` is an `Origin` record, NOT `JobBoards::Source` -- there's no FK between them, only a shared `name` established by `JobBoards::Syncer#resolve_dashboard_source`. `excluded_source?` does a name-based `JobBoards::Source.find_by(name: ...)` lookup to bridge them; documented inline since it's non-obvious and easy to get wrong (I got it wrong once, mid-task, and the test suite caught it immediately).
- `Admin::SourcesController#toggle_exclusion` now also enqueues `JobBoards::AuditJob` when turning exclusion ON, so already-ingested postings get swept without a separate manual step.
- Company-side of the original ask needed no new code at all: `/companies/:id` already has a working "Not Interested" button (`mark_not_interested_admin_company_path`) whose confirm text already says "future postings from them will be skipped automatically" -- verified this is real, not just copy.
- Verified against real data in a console smoke test: flagged the real Arbeitnow `JobBoards::Source`, confirmed a synthetic DE posting through that origin becomes non-useful, re-enabled, confirmed a US posting through the same origin is useful again.
- 4 new spec examples (QualityFilter) + 2 new (admin/sources toggle_exclusion sweep). Full suite: 628 examples, 0 failures.
<!-- SECTION:FINAL_SUMMARY:END -->
