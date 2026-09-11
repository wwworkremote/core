---
id: TASK-148
title: Inline edit-in-place for every field on the job posting show page
status: To Do
assignee: []
created_date: '2026-09-03 18:30'
labels:
  - job-search
  - ui
dependencies:
  - TASK-147.1
references:
  - app/controllers/job_postings_controller.rb
  - app/controllers/admin/job_postings_controller.rb
  - app/views/job_postings/show.html.erb
  - app/models/interview_process.rb
priority: medium
type: feature
ordinal: 169000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
## Why

Mike (2026-09-03): "I need to be able to update and revise pretty much any data on this page" — `/job_postings/7068`. Today the show page is almost entirely read-only: `JobPostingsController#update` permits only `title, company_name, location`; everything else (remote flag, salary, status, body, tags, the linked UserJobPosting's fields, interview rounds) can only be changed from the console or the separate `admin/job_postings` surface.

This is the power-user "admin + browsing merged" design (memory `product_design_power_user_tool`): the show page should be where Mike both reads and corrects a posting, not a read view with edits hidden behind a separate admin page.

## Decided UX (2026-09-03)

**Inline edit-in-place on the show page.** Each field / section becomes click-to-edit via Turbo frames — no separate edit page, no global edit-mode toggle. A field shows its value; clicking it swaps in an input + save/cancel; saving re-renders just that frame.

## Scope — editable data (all four groups)

1. **JobPosting core:** title, company (name / linked Company), location, remote flag, salary, employment type, url, status, posted date, body/description, `ai_category`, tags.
2. **UserJobPosting:** status, notes, priority flag, `applied_at`, outcome + outcome reason, match score / analysis.
3. **Interview rounds** (this absorbs TASK-147.1 AC#7): seed a process from an `InterviewProcess` template, add / remove / reorder rounds, edit each round's `scheduled_at` / `interviewers` / `outcome` / `notes` / `vibe` / `feedback`.
4. **Prep pack + Q&A:** already editable — bring the interaction into the same inline pattern for consistency (don't regress the existing copy/edit affordances).

## Constraints / notes

- Strong params per model need widening deliberately — `body` and `ai_category` feed downstream enrichment; changing `status` must still route through the AASM events / `record_status_event!`, not a raw column write.
- `remote` lives in `JobPosting#data` (jsonb), not a column — the "bad remote flag" that auto-ignored Basis on promote is exactly the kind of thing Mike needs to fix here.
- Keep it one power-user surface; don't build a parallel simplified editor.
- Auth: single-user app, `current_user` is the owner — no per-field permission model needed, but writes still go through the owning association (`current_user.user_job_postings...`), never `UserJobPosting.find`.

## References

- `app/controllers/job_postings_controller.rb` (update currently permits 3 fields)
- `app/controllers/admin/job_postings_controller.rb` (existing wider update — mine for permitted params + patterns, don't send Mike there)
- `app/views/job_postings/show.html.erb`
- TASK-147.1 (interview-round model + `InterviewProcess` templates already built; this task builds the round-editing UI that was its AC#7)
- Related dev-data context: Basis JP #7068 / UJP #268, AGENTS.md CURRENT FOCUS
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 JobPosting core fields (title, company, location, remote flag, salary, employment type, url, status, posted date, body, ai_category, tags) are all editable inline on /job_postings/:id and persist
- [ ] #2 UserJobPosting fields (status, notes, priority flag, applied_at, outcome + reason, match score/analysis) are editable inline for the current user's tracked posting; creating the UserJobPosting if none exists yet
- [ ] #3 status changes (JobPosting and UserJobPosting) route through the existing AASM events / record_status_event!, not raw column writes
- [ ] #4 remote flag edit writes JobPosting#data['remote'] correctly and is reflected by the same filters that auto-ignore on promote
- [ ] #5 Interview rounds: seed from an InterviewProcess template, add/remove/reorder rounds, and edit each round's scheduled_at/interviewers/outcome/notes/vibe/feedback inline (satisfies TASK-147.1 AC#7)
- [ ] #6 Prep pack and Q&A editing is brought into the same inline pattern without regressing the existing copy/edit/regenerate actions
- [ ] #7 Each editable field/section is its own Turbo frame: saving re-renders only that frame, cancel restores the read view, validation errors render in-frame
- [ ] #8 Strong params are widened per model with a comment on why each newly-permitted field is safe (esp. body, ai_category, status)
- [ ] #9 Request specs cover a successful inline edit + a validation-error render for at least one field per model (JobPosting, UserJobPosting, InterviewSession)
- [ ] #10 CONTEXT.md / relevant domain doc notes the show page is the canonical edit surface for a posting
<!-- AC:END -->
