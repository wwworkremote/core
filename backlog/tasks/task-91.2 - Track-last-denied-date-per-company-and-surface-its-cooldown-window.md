---
id: TASK-91.2
title: Track last-denied date per company and surface its cooldown window
status: Done
assignee: []
created_date: '2026-08-26 23:10'
updated_date: '2026-08-27 14:29'
labels: []
dependencies:
  - TASK-91.1
modified_files:
  - db/migrate/20260827131500_add_last_declined_at_to_companies.rb
  - app/models/company.rb
  - app/models/concerns/job_posting/legacy_company_access.rb
  - app/controllers/user_job_postings_controller.rb
  - app/controllers/admin/companies_controller.rb
  - config/routes.rb
  - app/views/admin/companies/show.html.erb
  - app/views/companies/show.html.erb
  - app/views/companies/index.html.erb
  - app/views/job_postings/show.html.erb
  - config/locales/en.yml
  - spec/models/company_spec.rb
  - spec/models/concerns/job_posting/legacy_company_access_spec.rb
  - spec/requests/admin/companies_spec.rb
  - spec/requests/companies_spec.rb
  - spec/requests/job_postings_spec.rb
  - spec/requests/user_job_postings_spec.rb
parent_task_id: TASK-91
priority: medium
type: feature
ordinal: 106000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
When a company declines Mike, he doesn't want to keep evaluating new postings from that company for 6 months — that's consistently a waste of time. Track the most recent decline date per company (`Company` model, db/schema.rb ~line 212 — currently has no such field) and let Mike see when a company is inside that cooldown window.

Depends on TASK-91.1 existing first if the trigger is "automatically set when a posting's outcome is marked rejected" — but the direct-set acceptance criterion below (for backfilling companies like Cengage without re-triggering a specific posting's outcome) can be built independently if sequencing works out that way.

Concrete starting case: Cengage, most recently declined via job posting #253.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Each company has a recorded most-recently-declined date
- [x] #2 Marking a posting's outcome as rejected (TASK-91.1) automatically updates that posting's company's most-recently-declined date
- [x] #3 The date can also be set directly on a company, independent of any specific posting's outcome, to backfill history (e.g. Cengage)
- [x] #4 The company's own page displays whether it's currently within the 6-month cooldown window and the date the cooldown ends
- [x] #5 A company page/listing that Mike browses while evaluating postings indicates when a company is in its cooldown window
- [x] #6 Marking a decline for a second posting at an already-cooling-down company updates the date to the more recent one rather than being blocked or ignored
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Company#last_declined_at + record_decline!/cooldown_ends_at/in_cooldown? (COOLDOWN = 6.months). record_decline! takes [current, new].compact.max, not a plain overwrite, so an out-of-order backfill can't regress a more recent decline (AC #6). Auto-recorded from UserJobPostingsController#apply_manual_outcome when outcome == "rejected" (AC #2); a direct admin backfill action (set_decline_date, AC #3) covers history like Cengage independent of any posting.

Surfaced in all 3 places AC #4/#5 asked for: the company's own page (cooldown-until badge), the companies index Mike browses (cooldown badge alongside the existing toxic-culture badge), and -- the most direct "evaluating this posting" spot -- the reputation card on the job posting page itself, next to the existing toxicity warning.

Real bug found and fixed while wiring this up: JobPosting::LegacyCompanyAccess#company_record returned nil whenever company_id was set directly (the correct/modern path), because it unconditionally ran Company.find_by(name: company) even when #company already returned the real Company object. This silently broke company_record for every posting with a resolved company_id -- including the pre-existing toxic_culture_flag reputation card, not just this task's new cooldown warning. Fixed at the source with a regression spec (5 examples) rather than working around it in the new code.

Verified live against the task's own named example: created the Cengage Company record, backfilled its decline date via record_decline!, confirmed the cooldown warning renders correctly on job posting #253's page and on Cengage's own company page (curl against the running dev server, since the browser extension was intermittently disconnected).

35 new/updated examples across 6 spec files, 0 failures, rubocop + erb_lint + i18n-tasks clean. Timezone bug caught by the test suite itself and fixed before completion: Date.iso8601(...).to_time silently used the system's local zone instead of Rails' configured Time.zone in the admin backfill action.
<!-- SECTION:FINAL_SUMMARY:END -->
