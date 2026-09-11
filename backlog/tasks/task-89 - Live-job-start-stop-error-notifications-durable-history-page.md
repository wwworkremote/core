---
id: TASK-89
title: Live job start/stop/error notifications + durable history page
status: Done
assignee: []
created_date: '2026-08-25 16:21'
updated_date: '2026-08-25 16:35'
labels: []
dependencies: []
priority: medium
type: feature
ordinal: 102000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
SolidQueue prunes finished job rows hourly (`clear_solid_queue_finished_jobs` in config/recurring.yml) and never recorded a `started_at` in the first place, so there's no durable record of "this job ran, took this long, and succeeded/failed" -- only whatever's currently sitting in solid_queue_jobs/failed_executions at any instant. /admin/jobs (Admin::JobsController::Dashboard) already surfaces a live snapshot (recurring_tasks, last_runs, recent_jobs, failed_jobs) but it's ephemeral, not a log.

Wanted: (1) a persistent history of every job run -- started, stopped, errored, with status -- visible as part of the site, and (2) a live alert/notification in the app when a job starts, stops, or errors.

## Proposed approach (no new gems -- turbo-rails + solid_cable/ActionCable are already installed)

1. New `JobRun` model/table: job_class, active_job_id, queue_name, status (running/finished/failed), started_at, finished_at, error_message. This is the durable log SolidQueue itself doesn't keep.
2. A single ActiveSupport::Notifications subscriber (one initializer) on `perform_start.active_job` (create the row, status: running) and `perform.active_job` (update it to finished/failed using `event.payload[:exception_object]`, correlated by active_job_id) -- covers every job in the app for free, no per-job-class changes.
3. Same subscriber broadcasts a Turbo Stream on each transition so any page showing `<%= turbo_stream_from "job_activity" %>` updates live without a refresh -- this is the "alert/notification" half.
4. A history view backed by JobRun (paginated, filterable by status/class) -- either its own page or folded into the existing /admin/jobs dashboard alongside a live-updating "recent activity" panel.

## Open questions to settle before/while building
- Where should the live notification appear -- global toast in the main site layout (visible on any page), or scoped to the admin/jobs dashboard only?
- Should the history page be under /admin or a top-level nav item? (Power-user tool merges admin+browsing per existing product-design convention, so either is consistent.)
- Retention: does JobRun need its own pruning job eventually, or is unbounded fine for now given current job volume (~900/week)?

## Acceptance criteria
- JobRun table exists and captures started_at/finished_at/status/error_message for every ActiveJob execution, independent of SolidQueue's own row pruning
- A page on the site shows JobRun history (recent runs, filterable by status at minimum)
- The site shows a live notification when a job starts, finishes, or errors, without a manual page refresh (Turbo Stream broadcast)
- Existing /admin/jobs dashboard functionality (trigger, discard, cancel, prune) is untouched
- Works for both the recurring-scheduled jobs (config/recurring.yml) and one-off enqueued jobs
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 JobRun table exists and captures started_at/finished_at/status/error_message for every ActiveJob execution, independent of SolidQueue's own row pruning
- [x] #2 A page on the site shows JobRun history (recent runs, filterable by status at minimum)
- [x] #3 The site shows a live notification when a job starts, finishes, or errors, without a manual page refresh (Turbo Stream broadcast)
- [x] #4 Existing /admin/jobs dashboard functionality (trigger, discard, cancel, prune) is untouched
- [x] #5 Works for both the recurring-scheduled jobs (config/recurring.yml) and one-off enqueued jobs
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Built per the confirmed approach: global toast notification (any page), history folded into /admin/jobs.

- `JobRun` model/table (migration 20260825162206): job_class, active_job_id, queue_name, status (running/finished/failed), started_at, finished_at, error_message.
- `config/initializers/job_run_tracking.rb`: single ActiveSupport::Notifications subscriber on `perform_start.active_job`/`perform.active_job`, covers every job in the app with no per-class changes. Correlates the two events by active_job_id.
- `JobRunBroadcaster` broadcasts a Turbo Stream (`job_activity` stream) on every transition; `app/views/layouts/application.html.erb` subscribes via `turbo_stream_from` and holds a `#job_activity_toasts` container. `app/views/job_runs/_toast.html.erb` + `toast_controller.js` (Stimulus, auto-dismiss after 5s) render it.
- `/admin/jobs` gained a third "Job History" tab backed by `JobRun.recent`, alongside the existing Recent Executions/Failed Jobs tabs (both untouched).

**Bug found and fixed during verification, not in the original plan:** the first working version caused a SystemStackError (`stack level too deep`) -- SolidCable's ActionCable adapter runs `SolidCable::TrimJob.perform_now` inline on every cable broadcast (`lib/action_cable/subscription_adapter/solid_cable.rb`). Tracking that job meant every JobRunBroadcaster.call triggered a cable message, which triggered TrimJob, which (being tracked) broadcast again -- infinite recursion, ~6500 bad rows created in seconds before I killed the runaway `bin/rails runner` process. Fixed by excluding `SolidCable::TrimJob` from tracking (`EXCLUDED_CLASSES` in the initializer) -- it's notification plumbing, not pipeline activity worth showing the user anyway. Verified clean with a timeout-guarded smoke test for both the success and failure paths afterward; full spec suite for spec/jobs, circuit_breaker_spec, and packages/ingestion/spec/jobs (68 examples) passes.
<!-- SECTION:FINAL_SUMMARY:END -->
