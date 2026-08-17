---
id: TASK-66.2
title: 'Display generated cover letters as their own artifact, not buried in Notes'
status: To Do
assignee: []
created_date: '2026-08-17 23:13'
updated_date: '2026-08-17 23:14'
labels:
  - ux
  - job-postings
  - ai
dependencies:
  - TASK-66.1
parent_task_id: TASK-66
type: enhancement
ordinal: 73000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Part of TASK-66, targets the unified page from the view-merge subtask. LLM::ArtifactGenerator (app/services/LLM/artifact_generator.rb) already generates a bespoke cover letter from CareerProfile/WorkExperience data via LLM::Orchestrator, triggered by the existing "Generate Pack" button (generate_artifacts_user_job_postings_path). Today attach_artifact appends the markdown output directly onto UserJobPosting#notes via string concatenation with a "### [GENERATED_COVER_LETTER]" marker, so it renders as unformatted text mixed into the free-text personal-notes textarea with no way to distinguish it from the user's own notes, no markdown rendering, and no copy action.

Give the generated cover letter its own distinct, rendered (markdown) panel on the job posting page, separate from personal notes, with a way to copy the text. Decide whether this requires a schema change (e.g. a dedicated column or a generated_artifacts association) or can reuse the existing notes storage with a less fragile way to extract just the generated portion for display -- either is acceptable as long as personal notes and generated content are visually and functionally distinct to the user.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The most recently generated cover letter is displayed as rendered markdown in its own panel, distinct from the personal notes field
- [ ] #2 A copy-to-clipboard (or equivalent) action is available for the generated cover letter text
- [ ] #3 Regenerating (clicking Generate Pack again) is reflected in the displayed panel without requiring a full page reload if the rest of the page already uses Turbo Streams for similar updates, otherwise a standard page refresh is acceptable
- [ ] #4 Existing personal notes content and behavior (the notes textarea/form) is unaffected
<!-- AC:END -->
