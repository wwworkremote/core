---
id: TASK-66.2
title: 'Display generated cover letters as their own artifact, not buried in Notes'
status: Done
assignee:
  - claude
created_date: '2026-08-17 23:13'
updated_date: '2026-08-18 00:01'
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
- [x] #1 The most recently generated cover letter is displayed as rendered markdown in its own panel, distinct from the personal notes field
- [x] #2 A copy-to-clipboard (or equivalent) action is available for the generated cover letter text
- [x] #3 Regenerating (clicking Generate Pack again) is reflected in the displayed panel without requiring a full page reload if the rest of the page already uses Turbo Streams for similar updates, otherwise a standard page refresh is acceptable
- [x] #4 Existing personal notes content and behavior (the notes textarea/form) is unaffected
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
While verifying with the full spec suite, found a pre-existing, order-dependent test-suite fragility unrelated to this task: spec/lib/wwwr/cli_spec.rb's "match" tests call User.sole (lib/wwwr/interop.rb:37/45) after their own create(:user), and spec/requests/charts/data/job_postings_spec.rb asserts an exact global JobPosting-derived count -- both assume the DB is otherwise empty. Under specific random --seed values (confirmed: 380), some other spec elsewhere in the 570+-example suite leaves an extra committed row behind, breaking that assumption. Confirmed via git stash that this exact seed passes cleanly on pre-TASK-66.2 code -- adding my 3 new examples shifted the RNG-seeded shuffle enough to newly expose it, not that my code leaks state directly (verified: my new specs alone, and paired with cli_spec.rb, pass in isolation). 3/3 unseeded full-suite runs afterward were clean. This is the third instance this session of this class of bug (queue_adapter leak fixed in ff99c7f3/ada10848, an ahoy trackClicks/trackSubmits test-env race fixed earlier today) -- flagging rather than fixing, since root-causing which spec leaks the row is unrelated to cover-letter display and would need its own task.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Gave the generated cover letter its own storage and display, separate from personal notes.

**What changed:**
- New migration: `user_job_postings.cover_letter` (text column), following the exact precedent of match_score/match_tags getting their own columns rather than living in strategy jsonb or notes.
- app/services/LLM/artifact_generator.rb#attach_artifact: now sets `cover_letter` directly instead of string-concatenating a "[GENERATED_COVER_LETTER]" marker onto `notes`.
- app/views/job_postings/show.html.erb: new "Cover Letter" panel (only rendered when present) between the Match Analysis and Personal Notes sections -- rendered markdown, plus a Copy button.
- app/javascript/controllers/clipboard_controller.js: new minimal Stimulus controller (this app's first beyond the scaffold stub) -- copies a hidden textarea's raw markdown value via navigator.clipboard.writeText, flips the button label to "Copied!" for 1.5s.
- Regeneration (clicking "Generate Application Pack" again) goes through the existing redirect_back_or_to flow, which already does a full page load -- satisfies AC #3's stated fallback, no turbo-stream work needed since that infrastructure isn't used elsewhere on this action.

**Tests:** spec/services/LLM/artifact_generator_spec.rb gained a spec asserting cover_letter and notes are stored independently. spec/requests/job_postings_spec.rb gained two specs for the panel (renders when present, distinct from notes; absent -- checked via the clipboard controller's data-controller attribute rather than the visible text, since an HTML *comment* marker in the view also contains the string "Cover Letter" and produced a false positive in my first draft of that assertion). Full suite: 574 examples, 0 failures (see implementation notes for an unrelated pre-existing flakiness found and documented, not fixed, while verifying). Rubocop and erb_lint clean.

**Manual verification:** set real cover_letter data on job posting 5817 in the dev DB, confirmed in a live browser that the panel renders correctly-converted markdown (bold, paragraphs), the hidden source textarea holds the raw markdown, the Copy button's label flips to "Copied!" on click, and the personal notes textarea remains empty/unaffected.

**Follow-ups still open on TASK-66:** TASK-66.3 (change-history detail) and TASK-66.4 (Q&A generator).
<!-- SECTION:FINAL_SUMMARY:END -->
