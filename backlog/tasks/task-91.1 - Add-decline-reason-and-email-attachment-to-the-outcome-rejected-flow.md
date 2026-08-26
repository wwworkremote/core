---
id: TASK-91.1
title: Add decline reason and email attachment to the outcome-rejected flow
status: To Do
assignee: []
created_date: '2026-08-26 23:10'
labels: []
dependencies: []
parent_task_id: TASK-91
priority: medium
type: feature
ordinal: 105000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Extend the existing "Mark Rejected" outcome control (app/views/job_postings/show.html.erb, `UserJobPosting#outcome`) so Mike can capture why he was declined and keep the rejection email as a durable record, at the moment he marks the outcome — not as a separate later step.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 User can enter a free-text reason at the same time they mark a posting's outcome as rejected
- [ ] #2 User can attach a file (e.g. the rejection email, forwarded as .eml, or a screenshot) to a rejected outcome
- [ ] #3 The reason and attachment are visible on the job posting page alongside the existing "Outcome: rejected" display
- [ ] #4 The existing "Clear" action also clears the reason and attachment, not just the outcome/outcome_at/outcome_source fields it clears today
- [ ] #5 Marking a rejected outcome with no reason or attachment provided continues to work exactly as it does today (both are optional)
<!-- AC:END -->
