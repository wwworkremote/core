---
id: TASK-64
title: Promote pipeline triage actions higher on the job posting show page
status: To Do
assignee: []
created_date: '2026-08-17 23:02'
labels:
  - ux
dependencies: []
type: enhancement
ordinal: 69000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Ahoy data analysis (see companion task "Surface job postings you keep reopening but haven't triaged") shows the dominant usage pattern for a meaningful slice of job postings is reopening the same posting repeatedly across sessions to decide what to do with it, rather than resolving it in one visit.

Currently in app/views/job_postings/show.html.erb, the "Apply on site" button is prominent near the top (around line 51), but the actual triage/decision controls -- Favorite / Apply / Interview / Offer / Archive / Not Interested / Expired (the "Pipeline" section, around lines 240-262) -- sit far down the page, below the personal notes form and activity logger.

Given the observed behavior is "come back to decide," having the decision controls that far below the fold works against the page's most common real use. Move the pipeline/triage action buttons higher on the page (or make them persistently visible, e.g. a sticky action bar) so the decision the user is actually there to make is immediately actionable.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Favorite/Apply/Interview/Offer/Archive/Not Interested/Expired controls are visible without scrolling past unrelated content (notes, activity log) on the job posting show page
- [ ] #2 Existing pipeline_steps_controller behavior and AASM guard logic (may_favorite? etc.) is unchanged -- this is a layout/placement change only
- [ ] #3 Change is verified in a real browser (not just specs) per project convention for UI changes
<!-- AC:END -->
