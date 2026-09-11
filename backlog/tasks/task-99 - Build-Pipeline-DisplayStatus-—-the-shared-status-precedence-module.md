---
id: TASK-99
title: 'Build Pipeline::DisplayStatus — the shared status-precedence module'
status: Done
assignee: []
created_date: '2026-08-27 11:51'
updated_date: '2026-08-27 11:53'
labels:
  - architecture
  - pipeline-status
dependencies: []
modified_files:
  - app/services/pipeline/display_status.rb
  - spec/services/pipeline/display_status_spec.rb
type: enhancement
ordinal: 114000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Deepens the pipeline/status cluster (TASK-82 phases 1-3 + same-session HumanTask addition) with one read-side seam that reconciles JobPosting.status (lifecycle AASM), UserJobPosting#outcome (plain string), and UserJobPosting.status (pipeline AASM) into a single badge decision. Currently this precedence chain is duplicated ad hoc in app/views/job_postings/show.html.erb (3 inline hashes) and, in narrower form, in app/views/user_job_postings/index.html.erb (an if/elsif on outcome alone).

Precedence to preserve exactly (pure refactor, no rule change): lifecycle (archived/ignored/expired/purged) > outcome (offered/rejected/reviewed/closed) > pipeline (favorited/applied/interview/archived). JobPosting's own "archived" wins over UserJobPosting's "archived" — a dead link outranks an old pipeline decision (see existing comment at job_postings/show.html.erb:23-29).

Bug found and folded into scope: show.html.erb's outcome_badges hash only has 2 of the 4 real MANUAL_OUTCOMES values ("offered"/"rejected") — "reviewed" and "closed" silently fall through to the pipeline tier today. Fix by building the outcome table with all 4 values, reusing the labels already correct in user_job_postings/index.html.erb ("Reviewed", "Posting closed").

Interface:
- `Pipeline::DisplayStatus.call(job_posting:, user_job:)` -> `{label:, semantic:}` or nil. Full 3-tier precedence, for the general caller (job_postings/show.html.erb).
- `Pipeline::DisplayStatus.outcome(user_job)` -> `{label:, semantic:}` or nil. Outcome tier only, for the narrower caller (user_job_postings/index.html.erb).

Returns a semantic key (e.g. :rejected, :archived_dead_link), not raw CSS — the two callers use different visual idioms (badge-outline vs pill) and must keep rendering their own current look. This task builds the module only; wiring the two view callers is TASK-B/TASK-C (dependents).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Pipeline::DisplayStatus.call implements all 3 precedence tiers with the exact existing rule, including the archived-both-tiers special case (JobPosting's archived wins)
- [x] #2 Pipeline::DisplayStatus.outcome covers all 4 outcome values (offered/rejected/reviewed/closed)
- [x] #3 Spec exercises every precedence branch plus the nil/no-badge case
- [x] #4 No view files touched in this task
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Pipeline::DisplayStatus built as two class methods over three frozen lookup tables (LIFECYCLE/OUTCOME/PIPELINE), no instance needed. .call implements the full 3-tier precedence; .outcome exposes just the outcome tier for the narrower caller. Outcome table now has all 4 MANUAL_OUTCOMES values (offered/rejected/reviewed/closed) -- fixes the reviewed/closed gap that existed in show.html.erb. 9 new examples, 0 failures, rubocop clean.
<!-- SECTION:FINAL_SUMMARY:END -->
