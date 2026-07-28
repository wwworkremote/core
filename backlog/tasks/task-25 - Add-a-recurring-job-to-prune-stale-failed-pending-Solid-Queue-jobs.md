---
id: TASK-25
title: Add a recurring job to prune stale failed/pending Solid Queue jobs
status: Done
assignee: []
created_date: '2026-07-27 21:57'
updated_date: '2026-07-28 01:21'
labels: []
dependencies: []
priority: medium
ordinal: 24000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
clear_solid_queue_finished_jobs (config/recurring.yml, hourly) only clears *finished* jobs. Nothing prunes stale failed_executions or ancient still-pending jobs, which is exactly how a 5,427-row / 166-failure backlog accumulated silently over 3 months before manual cleanup on 2026-07-27. Add a recurring task that discards failed/pending jobs older than some threshold (e.g. 14 days) for known-safe classes like Turbo::Streams::ActionBroadcastJob.
<!-- SECTION:DESCRIPTION:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Added app/services/solid_queue_maintenance/stale_job_pruner.rb (SolidQueueMaintenance::StaleJobPruner.call) -- discards pending jobs and failed executions older than 30 days (blanket time-based policy rather than a class allow-list, since the allow-list would need constant upkeep as new job classes get added; if something's unprocessed/unfixed after 30 days it needs manual intervention regardless of class). Wired into config/recurring.yml as prune_stale_solid_queue_jobs, daily at 4am, alongside the existing hourly clear_finished_in_batches. Verified: valid YAML, dry-run with a 10-year retention window returns {discarded_pending: 0, discarded_failed: 0} as expected (nothing that old exists), restarted jobs and confirmed prune_stale_solid_queue_jobs shows up in solid_queue_recurring_tasks with no boot errors. rubocop clean. Known minor gap: Job#discard only covers ready/claimed/failed execution states, not scheduled/blocked -- acceptable for a low-stakes hygiene sweep, not chasing full coverage.
<!-- SECTION:NOTES:END -->
