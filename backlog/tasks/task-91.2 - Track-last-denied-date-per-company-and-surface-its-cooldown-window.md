---
id: TASK-91.2
title: Track last-denied date per company and surface its cooldown window
status: To Do
assignee: []
created_date: '2026-08-26 23:10'
labels: []
dependencies:
  - TASK-91.1
parent_task_id: TASK-91
priority: medium
type: feature
ordinal: 106000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
When a company declines Mike, he doesn't want to keep evaluating new postings from that company for 6 months — that's consistently a waste of time. Track the most recent decline date per company (`Company` model, db/schema.rb ~line 212 — currently has no such field) and let Mike see when a company is inside that cooldown window.

Depends on TASK-91.1 existing first if the trigger is "automatically set when a posting's outcome is marked rejected" — but the direct-set acceptance criterion below (for backfilling companies like Cengage without re-triggering a specific posting's outcome) can be built independently if sequencing works out that way.

Concrete starting case: Cengage, most recently declined via job posting #253.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Each company has a recorded most-recently-declined date
- [ ] #2 Marking a posting's outcome as rejected (TASK-91.1) automatically updates that posting's company's most-recently-declined date
- [ ] #3 The date can also be set directly on a company, independent of any specific posting's outcome, to backfill history (e.g. Cengage)
- [ ] #4 The company's own page displays whether it's currently within the 6-month cooldown window and the date the cooldown ends
- [ ] #5 A company page/listing that Mike browses while evaluating postings indicates when a company is in its cooldown window
- [ ] #6 Marking a decline for a second posting at an already-cooling-down company updates the date to the more recent one rather than being blocked or ignored
<!-- AC:END -->
