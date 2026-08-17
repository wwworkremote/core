---
id: TASK-59
title: Add manual "Mark as Expired" action for job postings
status: Done
assignee: []
created_date: '2026-08-17 01:07'
updated_date: '2026-08-17 01:14'
labels: []
dependencies: []
modified_files:
  - app/controllers/admin/pipeline_steps_controller.rb
  - app/views/job_postings/show.html.erb
  - app/views/job_postings/index.html.erb
  - config/locales/en.yml
  - spec/requests/admin/pipeline_steps_spec.rb
priority: high
type: feature
ordinal: 40000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The AASM state machine already has an `expired` status and `expire` event (`app/models/concerns/job_posting/status_workflow.rb:26-28`, transitions from `none/favorited/archived/ignored` -> `expired`), and `JobLifecycle::ExpirySweepJob` auto-expires postings 72h+ past `published_at` (`app/jobs/job_lifecycle/expiry_sweep_job.rb`). But there's no manual trigger: `Admin::PipelineStepsController::STATUS_EVENTS` (`app/controllers/admin/pipeline_steps_controller.rb:8-15`) only maps favorite/apply/interview/offer/archive/ignore, no "expire". So a posting that's actually dead (link 404s, listing pulled) but hasn't hit the 72h sweep threshold yet has no way to be marked expired by the user -- unlike "Not Interested" (`ignore`), which has a button in both `job_postings/index.html.erb:114` and `job_postings/show.html.erb:255`.

Add "expire" to `STATUS_EVENTS`, then add a "Mark Expired" button alongside the existing "Not Interested" button in both views, posting to the same `admin_job_posting_pipeline_steps_path(@job_posting)` with `status: 'expire'`. Follow the existing ignore-button pattern (AASM guard via `may_expire?` already prevents invalid transitions, same double-click/stale-page protection `apply_status_event` already provides for every other event).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 "Mark Expired" button visible on job posting index and show views
- [x] #2 Clicking it transitions status to expired via the existing AASM event, same pattern as the ignore/"Not Interested" button
- [x] #3 Invalid transitions (e.g. already purged) no-op instead of raising, consistent with apply_status_event's existing guard behavior
- [x] #4 Manually-expired postings are excluded from default job posting listings the same way ignored/archived ones are
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added "expire" to Admin::PipelineStepsController::STATUS_EVENTS (existing AASM event/state, no model changes needed) and a "Mark Expired" button next to "Not Interested" on both job_postings/show (labeled button) and job_postings/index (icon button, turbo-stream card removal, same pattern as ignore). Default listing already excluded status: expired, so no query changes needed. Added request specs for the happy path and the invalid-transition no-op case.
<!-- SECTION:FINAL_SUMMARY:END -->
