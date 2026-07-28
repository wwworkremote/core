---
id: TASK-24
title: 'Fix or remove the orphaned :low Solid Queue worker group'
status: To Do
assignee: []
created_date: '2026-07-27 21:57'
labels: []
dependencies: []
priority: medium
ordinal: 23000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Quality::InsightEmbeddingJob and JobLifecycle::ExpirySweepJob are queue_as :low, but config/queue.yml only defines worker groups for heavy/light/default -- no worker ever polls :low. Anything enqueued there sits in ready_executions forever regardless of load, silently. Either add a :low worker group or move these jobs to an existing queue.
<!-- SECTION:DESCRIPTION:END -->
