---
id: TASK-98
title: No persona-filtered resume file export exists (JSON snapshot only)
status: To Do
assignee: []
created_date: '2026-08-27 02:21'
updated_date: '2026-08-27 02:31'
labels: []
dependencies: []
references:
  - docs/agents/peer-contract-just3ws.md
  - docs/just3ws-interop-protocol.md
  - app/services/resume/persona_context.rb
  - app/services/resume_export_service.rb
  - TASK-97
priority: medium
type: feature
ordinal: 113000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Discovered during the 2026-08-27 live LinkedIn pipeline test (JobPosting #6828, Karias Health): `Resume::PersonaContext` produces a tailored persona snapshot (title/summary/positions/core_skills) and stores it as JSON on `UserJobPosting#resume_persona_snapshot`, but nothing renders that snapshot into an uploadable document. Checked both places a renderer might live:

- This repo's `ResumeExportService`/`ResumeManager` (to_markdown/to_pdf/etc.) operates on a completely different, unused data model (`Resume` ActiveRecord, 0 rows in the DB) -- dead code path, not wired to personas at all.
- The peer `just3ws.localhost` repo's `/exports/resume.md` and `/exports/portfolio.md` endpoints (docs/just3ws-interop-protocol.md) export the full canonical resume, not persona-filtered.

Net result: there is no button or endpoint anywhere that turns "I picked persona X for this job" into an actual resume file to attach to an application. Had to hand-render one from the snapshot JSON manually to complete the live test.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A persona snapshot (UserJobPosting#resume_persona_snapshot) can be rendered to at least Markdown (PDF is a stretch goal, not required) without manual intervention
- [ ] #2 The render is reachable from the job posting page or the extension's review panel -- not just a rails console/service call
- [ ] #3 Decide and document which repo owns this: extend wwworkremote's dormant ResumeExportService to consume persona snapshots instead of the unused Resume AR model, or add a persona-filtered export mode to just3ws.localhost and call it via the existing interop pattern -- do not build a third parallel resume-rendering path
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Correction from Mike: the persona/archetype definitions themselves already live in just3ws.localhost (fetched live via Resume::Source from /resume.json, see app/services/resume/source.rb) -- wwworkremote only fetches and snapshots them, it doesn't own the source data. Since just3ws already has both the archetype definitions AND an existing markdown export pipeline (/exports/resume.md), the natural fix is almost certainly adding an archetype/persona filter to that existing just3ws export (e.g. /exports/resume.md?archetype=founding_staff_fullstack), not building a second rendering pipeline in wwworkremote against fetched JSON. Re-evaluate AC #3 with this in mind before starting -- just3ws is the likely sole owner here, not a fallback option.

Correction (2nd): just3ws.github.io already has this built and published -- exports/resumes/mike-hall-<slug>.{json,md,txt} exist for all 5 archetypes right now (e.g. mike-hall-founding-staff-engineer.md), matching Resume::PersonaContext's archetype IDs exactly. This was found by browsing the just3ws checkout directly, not via any endpoint wwworkremote currently calls. So the real gap is much smaller than originally scoped: wwworkremote needs to (a) fetch the matching /exports/resumes/mike-hall-<slug>.md from just3ws instead of only ever calling /resume.json, and (b) convert that markdown to DOCX/PDF for actual ATS upload (pandoc handles md->docx with zero extra dependencies, verified working 2026-08-27). No new content-generation work is needed on either side -- this is purely a fetch-the-existing-thing-and-convert-format task now.
<!-- SECTION:NOTES:END -->
