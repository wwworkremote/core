---
id: TASK-148
title: Inline edit-in-place for every field on the job posting show page
status: In Progress
assignee: []
created_date: '2026-09-03 18:30'
updated_date: '2026-09-03 18:48'
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
- `remote` lives in `JobPosting#data` (jsonb), not a column — the "bad remote flag" that auto-ignored [redacted] on promote is exactly the kind of thing Mike needs to fix here.
- Keep it one power-user surface; don't build a parallel simplified editor.
- Auth: single-user app, `current_user` is the owner — no per-field permission model needed, but writes still go through the owning association (`current_user.user_job_postings...`), never `UserJobPosting.find`.

## References

- `app/controllers/job_postings_controller.rb` (update currently permits 3 fields)
- `app/controllers/admin/job_postings_controller.rb` (existing wider update — mine for permitted params + patterns, don't send Mike there)
- `app/views/job_postings/show.html.erb`
- TASK-147.1 (interview-round model + `InterviewProcess` templates already built; this task builds the round-editing UI that was its AC#7)
- Related dev-data context: [redacted] JP #7068 / UJP #268, AGENTS.md CURRENT FOCUS
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 JobPosting core fields (title, company, location, remote flag, salary, employment type, url, status, posted date, body, ai_category, tags) are all editable inline on /job_postings/:id and persist
- [ ] #2 UserJobPosting fields (status, notes, priority flag, applied_at, outcome + reason, match score/analysis) are editable inline for the current user's tracked posting; creating the UserJobPosting if none exists yet
- [ ] #3 status changes (JobPosting and UserJobPosting) route through the existing AASM events / record_status_event!, not raw column writes
- [x] #4 remote flag edit writes JobPosting#data['remote'] correctly and is reflected by the same filters that auto-ignore on promote
- [ ] #5 Interview rounds: seed from an InterviewProcess template, add/remove/reorder rounds, and edit each round's scheduled_at/interviewers/outcome/notes/vibe/feedback inline (satisfies TASK-147.1 AC#7)
- [ ] #6 Prep pack and Q&A editing is brought into the same inline pattern without regressing the existing copy/edit/regenerate actions
- [ ] #7 Each editable field/section is its own Turbo frame: saving re-renders only that frame, cancel restores the read view, validation errors render in-frame
- [ ] #8 Strong params are widened per model with a comment on why each newly-permitted field is safe (esp. body, ai_category, status)
- [ ] #9 Request specs cover a successful inline edit + a validation-error render for at least one field per model (JobPosting, UserJobPosting, InterviewSession)
- [ ] #10 CONTEXT.md / relevant domain doc notes the show page is the canonical edit surface for a posting
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Building in slices, each its own commit, on branch `feat/inline-edit-job-posting` (stacked on PR #23's `feat/homepage-pipeline-blocks`).

SLICE 1 — JobPosting core (commit 71f825b7) — DONE:
- `app/models/concerns/job_posting/inline_editing.rb`: flat form accessors (`remote=`, `countries_text=`, `tags_text=`, `store_accessor :data` for employment_type/salary_min/salary_max/currency) translating to `data` jsonb / `tags` array with dirty tracking. Controller just permits scalars (`JobPostingsController::EDIT_FIELDS`).
- Multi-country (AC#4): `data["countries"]` array is the editable multi-value layer; `JobPosting.geo_allowed` passes if US is in `country_code` OR `data["countries"]`. `country_code` stays the single geocoded scalar.
- `app/views/job_postings/_core_form.html.erb` + a `turbo_frame_tag dom_id(@job_posting, :core)` on the show page. `?section=core` renders the form; save redirects back → frame re-renders display; `render_edit_errors` re-renders with errors (path exists; JobPosting has ~no reachable validations through EDIT_FIELDS, untested).
- Fields: title, company_name, location (free text, multi-location), countries, target_url, published_at, employment_type, salary min/max, currency, remote, tags.
- `CONTEXT.md` Job Posting entry updated: show page is the canonical edit surface.
- Specs: `job_posting_spec.rb` (accessors + geo_allowed multi-country), `job_postings_spec.rb` (inline edit of location/countries/tags, `?section=core` renders).
- Dev data: JP #7068 corrected — location "Chicago, IL · Toronto, ON", country_code US, countries [US,CA]; Centro note on UJP #268.

REMAINING SLICES (not started):
- AC#1: JobPosting core done; `body` / `ai_category` edit still not wired (description section is reformat-only).
- AC#2/#3: UserJobPosting inline edit (notes, priority_flag, applied_at). `user_job_postings#update` already permits `:notes`; add priority_flag/applied_at, redirect back to the posting, add a turbo-frame section. Status/outcome keep their existing dedicated button flows.
- AC#5: interview-round editing UI (seed from `InterviewProcess` template, per-round scheduled_at/interviewers/outcome/notes, add/remove/reorder). Absorbs TASK-147.1 AC#7.
- AC#6: fold prep-pack / Q&A editors into the same inline pattern (currently `<details>`; low priority, they work).
- AC#7 satisfied by slice 1's turbo-frame approach; reuse for other sections.
- AC#9/#10: extend per slice.
<!-- SECTION:NOTES:END -->

## Comments

<!-- COMMENTS:BEGIN -->
created: 2026-09-03 18:48
---
Slice 1 (JobPosting core fields + multi-country data['countries'] + geo_allowed honoring it) shipped on branch feat/inline-edit-job-posting, commit 71f825b7. Directly unblocks the Basis multi-location / multi-country need. Remaining slices (UserJobPosting fields, interview-round UI, prep/Q&A) not started — breakdown in Implementation Notes.
---
<!-- COMMENTS:END -->
