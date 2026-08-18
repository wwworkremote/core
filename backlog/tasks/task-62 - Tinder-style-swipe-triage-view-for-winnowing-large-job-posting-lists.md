---
id: TASK-62
title: Tinder-style swipe triage view for winnowing large job posting lists
status: To Do
assignee: []
created_date: '2026-08-17 12:23'
updated_date: '2026-08-17 23:36'
labels: []
dependencies: []
priority: medium
type: feature
ordinal: 67000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Noted mid-session for later, not started. Idea: a dedicated one-at-a-time review UI for job_postings -- swipe/click left for Not Interested (TASK-59 hooked this up: ignore), right to Favorite, maybe a third gesture for Expired (TASK-59) -- to burn through a large backlog of untriaged postings quickly instead of the current list view where each action is a separate button click on a card.

Needs design/UX decisions before implementation: keyboard shortcuts vs. actual swipe gestures, whether it's a new route/view or a mode on job_postings#index, what the "queue" ordering is (newest first? match score?), and whether skipping (no action) advances without changing status.

Refined 2026-08-17 with more detail from the user: the goal is specifically to cut through noise fast for a large volume of postings, so the queue should exclude anything already triaged (favorited, or any other non-"none" status) -- it's a first-pass winnowing tool, not a replacement for the full pipeline/show page. Each swipe should optionally capture structured signal for future analysis, not just the binary status change: a couple of multiple-choice criteria (e.g. "good match on industry, bad match on skill set/seniority" -- exact criteria list needs design) plus an optional free-text note, attached to the resulting pipeline_step so the reasoning behind a decision is queryable later, not just the decision itself.
<!-- SECTION:DESCRIPTION:END -->
