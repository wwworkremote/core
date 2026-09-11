---
id: TASK-96
title: >-
  Self-describing timeline of ingestion sync attempts, not just pipeline
  decisions
status: To Do
assignee: []
created_date: '2026-08-27 00:20'
labels: []
dependencies: []
references:
  - TASK-82
priority: medium
type: feature
ordinal: 111000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Mike wants to see, per job posting, a timeline of ingestion sync/re-crawl attempts and how the posting's data changed as a result -- not just the pipeline-decision timeline (PipelineStep) that already exists on the job posting page. Everything on it should be self-describing (readable in plain language, not requiring the reader to decode internal status codes or job names).

JobPosting already has `seen_count`, `crawl_status`, and `enriched_at` (a counter and two point-in-time fields, not a history), and there's a separate `JobBoards::Document` model in packages/ingestion referenced in docs/architecture.md as the raw-data staging table before normalization -- whether that already retains enough history to build this timeline, or whether new tracking is needed, is for whoever picks this up to determine.

Related but distinct from TASK-82: that task is about which model owns which *decision* state; this task is about the *provenance* history of re-syncing a posting's data over time.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The job posting page shows a timeline of ingestion sync/re-crawl attempts, separate from or merged with the existing pipeline-decision timeline, with UI making clear which is which
- [ ] #2 Each timeline entry describes what happened in plain language (e.g. what changed about the posting on that sync), not just a status code or timestamp
- [ ] #3 Failed or no-op sync attempts are visible too, not just ones that changed something
<!-- AC:END -->
