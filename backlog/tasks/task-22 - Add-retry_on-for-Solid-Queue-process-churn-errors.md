---
id: TASK-22
title: Add retry_on for Solid Queue process-churn errors
status: To Do
assignee: []
created_date: '2026-07-27 21:57'
updated_date: '2026-07-28 00:13'
labels: []
dependencies: []
priority: high
ordinal: 21000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
76%% of all failed_executions (127 of 166 as of 2026-07-27) were SolidQueue::Processes::ProcessPrunedError/ProcessMissingError -- a worker process died mid-job (dev restarts, deploys) and orphaned in-flight work. Zero retry_on/discard_on exists anywhere in app/jobs or packages/ingestion/app/jobs, so none of this self-heals; every restart permanently strands whatever was running. Add retry_on SolidQueue::Processes::ProcessPrunedError, SolidQueue::Processes::ProcessMissingError, wait: 30.seconds, attempts: 3 to ApplicationJob.
<!-- SECTION:DESCRIPTION:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Added retry_on SolidQueue::Processes::ProcessPrunedError, SolidQueue::Processes::ProcessMissingError, wait: 30.seconds, attempts: 3 to ApplicationJob. Verified both classes are real StandardError subclasses and the handler registered correctly via a runner check. rubocop clean.
<!-- SECTION:NOTES:END -->
