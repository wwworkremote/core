---
id: TASK-100
title: 'Wire Pipeline::DisplayStatus into job_postings/show.html.erb'
status: Done
assignee: []
created_date: '2026-08-27 11:51'
updated_date: '2026-08-27 11:55'
labels:
  - architecture
  - pipeline-status
dependencies:
  - TASK-99
modified_files:
  - app/views/job_postings/show.html.erb
  - app/helpers/job_postings_helper.rb
  - spec/requests/job_postings_spec.rb
type: enhancement
ordinal: 115000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
General/most-common caller. Replace the 3 inline badge hashes and precedence line (app/views/job_postings/show.html.erb:30-46) with one call: Pipeline::DisplayStatus.call(job_posting: @job_posting, user_job: user_job). Map the returned semantic key to this view's existing badge-outline CSS classes (unchanged per-semantic styling).

This is also where TASK-99's bug fix becomes visible: outcomes "reviewed" and "closed" will render a badge for the first time on this page instead of silently falling through to the pipeline tier.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Visual output identical to today for every previously-covered case (archived/ignored/expired/purged/offered/rejected/favorited/applied/interview/no-badge)
- [x] #2 "reviewed" and "closed" outcomes now render the correct badge on the show page
- [x] #3 View/request spec covers at least one case per tier plus both newly-fixed outcomes
- [x] #4 The 3 inline hashes and the manual precedence line are deleted from the view
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Replaced the 3 inline hashes + precedence line with Pipeline::DisplayStatus.call. Added a pipeline_status_badge helper (matching the existing answer_source_badge convention in the same helper file) to keep CSS mapping in the helper, not the view -- the view now does one call and one badge_class/badge_label destructure. 3 new request specs (reviewed, closed, archived-precedence); 30/30 examples pass; rubocop + erb_lint clean.
<!-- SECTION:FINAL_SUMMARY:END -->
