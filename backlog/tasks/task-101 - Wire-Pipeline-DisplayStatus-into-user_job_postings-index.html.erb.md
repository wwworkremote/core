---
id: TASK-101
title: 'Wire Pipeline::DisplayStatus into user_job_postings/index.html.erb'
status: Done
assignee: []
created_date: '2026-08-27 11:51'
updated_date: '2026-08-27 11:57'
labels:
  - architecture
  - pipeline-status
dependencies:
  - TASK-99
modified_files:
  - app/views/user_job_postings/index.html.erb
  - app/helpers/user_job_postings_helper.rb
  - spec/requests/user_job_postings_spec.rb
type: enhancement
ordinal: 116000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Specific/narrower caller. Replace the inline if/elsif outcome branch (app/views/user_job_postings/index.html.erb:96-100) with Pipeline::DisplayStatus.outcome(user_job), mapping the returned semantic key to this view's existing pill CSS classes.

Pure dedup, no behavior change expected — this view already covers all 4 outcome values today, it just re-derives the label/CSS per row instead of calling the shared table. Use .outcome, not .call: this card already renders its own unconditional "Applied" pill separately above this block, so calling the full 3-tier .call here would risk a duplicate or conflicting "Applied" badge from the pipeline tier.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Visual output identical to today for rejected/reviewed/closed/no-outcome
- [x] #2 Only Pipeline::DisplayStatus.outcome is used here, not .call
- [x] #3 View/request spec covers all 4 outcome values plus the outcome-blank case
- [x] #4 The inline if/elsif block is deleted from the view
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added UserJobPostingsHelper#outcome_badge wrapping Pipeline::DisplayStatus.outcome only (not .call), matching this view's own note that the "Applied" pill is already rendered separately. Preserved the pre-existing gap where "offered" outcome shows no badge here (OUTCOME_BADGE_CLASSES has no entry for it, helper returns nil rather than raising) -- exact behavior parity, not a new feature. Added the first GET /user_job_postings request spec coverage (4 examples); 14/14 pass; rubocop + erb_lint clean.
<!-- SECTION:FINAL_SUMMARY:END -->
