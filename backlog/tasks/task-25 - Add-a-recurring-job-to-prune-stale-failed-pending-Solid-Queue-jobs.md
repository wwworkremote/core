---
id: TASK-25
title: Add a recurring job to prune stale failed/pending Solid Queue jobs
status: To Do
assignee: []
created_date: '2026-07-27 21:57'
labels: []
dependencies: []
priority: medium
ordinal: 24000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
clear_solid_queue_finished_jobs (config/recurring.yml, hourly) only clears *finished* jobs. Nothing prunes stale failed_executions or ancient still-pending jobs, which is exactly how a 5,427-row / 166-failure backlog accumulated silently over 3 months before manual cleanup on 2026-07-27. Add a recurring task that discards failed/pending jobs older than some threshold (e.g. 14 days) for known-safe classes like Turbo::Streams::ActionBroadcastJob.
<!-- SECTION:DESCRIPTION:END -->
