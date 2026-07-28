---
id: TASK-23
title: Apply concurrency limits to heavy job classes
status: To Do
assignee: []
created_date: '2026-07-27 21:57'
labels: []
dependencies: []
priority: medium
ordinal: 22000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
ApplicationJob already provides heavyweight!/mediumweight!/lightweight!/idempotent! (Solid Queue's limits_concurrency). Only LLM::BatchMatchJob actually uses it. JobBoards::GeocodingJob, JobBoards::ContentEnrichmentJob, and EmailIngestion::ImportJob (launches Playwright) have no per-class concurrency ceiling -- the only throttle is the shared queue-level thread count in config/queue.yml, so one heavy class can monopolize a whole worker pool. Apply the existing helpers to these classes.
<!-- SECTION:DESCRIPTION:END -->
