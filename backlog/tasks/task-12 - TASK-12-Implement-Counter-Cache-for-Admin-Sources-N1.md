---
id: TASK-12
title: 'TASK-12: Implement Counter Cache for Admin::Sources N+1'
status: Done
assignee: []
created_date: '2026-05-23 12:57'
updated_date: '2026-08-16 14:32'
labels: []
dependencies: []
priority: medium
ordinal: 12000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Resolve the Bullet::Notification::UnoptimizedQueryError in Admin::Sources by implementing a counter cache. This improves performance and eliminates N+1 query patterns in the admin index.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 'Bullet' error in Admin::Sources spec is resolved.
- [x] #2 Counter cache implemented for 'job_boards_documents' association in 'JobBoards::Source'.
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Stale -- already fixed 3 weeks before this audit (same commit as TASK-11), just never closed. Commit c1ca2528 (2026-07-28) added migration add_job_boards_documents_count_to_job_boards_sources (job_boards_documents_count integer, default 0, not null), wired counter_cache: :job_boards_documents_count on the JobBoards::Document -> JobBoards::Source association (packages/ingestion/app/models/job_boards/document.rb:25), and updated both admin/sources views to read the cached count column instead of triggering N+1 queries.

Verified live 2026-08-16: spec/requests/admin/sources_spec.rb passes (2 examples, no Bullet::Notification::UnoptimizedQueryError).
<!-- SECTION:FINAL_SUMMARY:END -->
