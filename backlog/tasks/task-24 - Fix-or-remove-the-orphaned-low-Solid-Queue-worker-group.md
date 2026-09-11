---
id: TASK-24
title: 'Fix or remove the orphaned :low Solid Queue worker group'
status: Done
assignee: []
created_date: '2026-07-27 21:57'
updated_date: '2026-07-28 01:06'
labels: []
dependencies: []
priority: medium
ordinal: 23000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Quality::InsightEmbeddingJob and JobLifecycle::ExpirySweepJob are queue_as :low, but config/queue.yml only defines worker groups for heavy/light/default -- no worker ever polls :low. Anything enqueued there sits in ready_executions forever regardless of load, silently. Either add a :low worker group or move these jobs to an existing queue.
<!-- SECTION:DESCRIPTION:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Fixed (not removed): added a 'low' worker group to config/queue.yml (1 thread, default/dev/prod), matching the existing pattern for heavy/light/default/broadcasts. Chose fix over remove since Quality::InsightEmbeddingJob and JobLifecycle::ExpirySweepJob are both real, non-trivial jobs (embedding generation, posting expiry) worth their own lower-priority tier rather than merging into :light. Verified: restarted jobs, solid_queue_processes now shows heavy/light/default/broadcasts/low all registered, no boot errors. While investigating, found ExpirySweepJob was never even in recurring.yml (2,343 stale postings as a result) -- filed separately as TASK-30 since fixing the queue gap and adding the actual schedule are two different fixes.
<!-- SECTION:NOTES:END -->
