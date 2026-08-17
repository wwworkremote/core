---
id: TASK-66
title: Unify job posting view and complete the AI application-assistance workflow
status: To Do
assignee: []
created_date: '2026-08-17 23:13'
labels:
  - ux
  - job-postings
  - ai
dependencies: []
type: feature
ordinal: 71000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The app currently has two separate MVC stacks over the same JobPosting record: Admin::JobPostingsController + app/views/admin/job_postings (Enrich Data, Synthesize, Purge/Restore, pipeline actions) and JobPostingsController + app/views/job_postings (Apply on site, AI match analysis, cover letter generation, pipeline actions, personal notes). These diverged over time rather than by design, and the admin page is missing features (match analysis, cover letter generation, Q&A) that already exist and work on the non-admin page.

Decision made with the user: merge into a single canonical job posting view/URL (job_postings/:id), with admin-only actions (Enrich Data, Synthesize, Purge/Restore, bulk operations) gated by an authorization check rather than living behind a separate controller/route namespace.

While auditing this page, three other gaps were found where backend capability already exists but has no UI:
- Cover letter generation (LLM::ArtifactGenerator + PromptBuilder, already wired to a "Generate Pack" button on the non-admin page) appends its markdown output directly into the free-text personal-notes field via string concatenation (see attach_artifact in app/services/LLM/artifact_generator.rb) instead of being stored/displayed as its own artifact -- it currently shows up as unrendered text mixed into the Notes textarea.
- JobPosting already has `has_paper_trail` declared and is actively recording versions (confirmed non-empty `versions` table in dev) on every save, including from JobBoards::Reformatter/JobPostingReformatJob -- but no view anywhere renders that history.
- Application screening questions (the "why do you want to work here"-style questions on job applications) have no representation in the data model or UI at all. The user wants to submit a set of these per application and get answers primed from their CareerProfile/WorkExperience history -- some questions answerable directly from structured profile data ("canned" answers, no LLM needed), others complex/open-ended enough to need an LLM call, decided per-question by complexity.

This parent task tracks the initiative; each piece is broken into a subtask since they touch different subsystems and can land somewhat independently, but the UI-facing ones (cover letter display, history, Q&A) should target the unified page produced by the view-merge subtask rather than the soon-to-be-retired admin-only page.
<!-- SECTION:DESCRIPTION:END -->
