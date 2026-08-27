---
id: TASK-91.1
title: Add decline reason and email attachment to the outcome-rejected flow
status: Done
assignee: []
created_date: '2026-08-26 23:10'
updated_date: '2026-08-27 13:09'
labels: []
dependencies: []
modified_files:
  - db/migrate/20260827130000_add_outcome_reason_to_user_job_postings.rb
  - app/models/user_job_posting.rb
  - app/controllers/user_job_postings_controller.rb
  - app/views/job_postings/show.html.erb
  - spec/requests/user_job_postings_spec.rb
  - spec/requests/job_postings_spec.rb
  - spec/fixtures/files/sample.txt
parent_task_id: TASK-91
priority: medium
type: feature
ordinal: 105000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Extend the existing "Mark Rejected" outcome control (app/views/job_postings/show.html.erb, `UserJobPosting#outcome`) so Mike can capture why he was declined and keep the rejection email as a durable record, at the moment he marks the outcome — not as a separate later step.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 User can enter a free-text reason at the same time they mark a posting's outcome as rejected
- [x] #2 User can attach a file (e.g. the rejection email, forwarded as .eml, or a screenshot) to a rejected outcome
- [x] #3 The reason and attachment are visible on the job posting page alongside the existing "Outcome: rejected" display
- [x] #4 The existing "Clear" action also clears the reason and attachment, not just the outcome/outcome_at/outcome_source fields it clears today
- [x] #5 Marking a rejected outcome with no reason or attachment provided continues to work exactly as it does today (both are optional)
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
outcome_reason (text column) + outcome_evidence (has_one_attached, reusing the ActiveStorage setup already used by PipelineStep/CareerProfile) on UserJobPosting. "Mark Rejected" became a <details> disclosure holding a small multipart form (reason textarea + file field) instead of a single-click button_to -- native HTML, no JS -- so both are optional and captured at the moment of marking, not a separate step. Offered/reviewed/closed stay single-click, unaffected.

Clear now nulls outcome_reason and outcome_evidence too (assigning nil to a has_one_attached purges it), added to CLEARABLE_OUTCOME_ATTRS alongside the pre-existing outcome/outcome_at/outcome_source. The existing security boundary is preserved and covered by a new spec: PATCH still can't set a real outcome+reason directly, only clear one -- setting one still requires going through apply_manual_outcome's fixed-vocabulary path in #create.

11 new/updated examples (POST reason/evidence/no-op-unchanged, PATCH clears-both/still-blocked, GET shows reason+evidence link and the neither-present case), 0 failures, rubocop + erb_lint clean.
<!-- SECTION:FINAL_SUMMARY:END -->
