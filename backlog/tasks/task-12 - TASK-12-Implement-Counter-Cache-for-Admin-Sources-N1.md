---
id: TASK-12
title: 'TASK-12: Implement Counter Cache for Admin::Sources N+1'
status: To Do
assignee: []
created_date: '2026-05-23 12:57'
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
- [ ] #1 'Bullet' error in Admin::Sources spec is resolved.
- [ ] #2 Counter cache implemented for 'job_boards_documents' association in 'JobBoards::Source'.
<!-- AC:END -->
