---
id: TASK-120
title: 'Extension: capture job_post_id in a guided session against the sandbox'
status: Done
assignee: []
created_date: '2026-08-29 15:50'
updated_date: '2026-08-29 15:58'
labels:
  - reference-comparison
  - extension
  - guided-session
dependencies: []
references:
  - docs/adr/009-reference-comparison-drift-and-coverage.md
  - >-
    backlog/docs/wayfinder/doc-6 -
    Wayfinder-map-Reference-Comparison-drift-loop.md
  - app/services/scenarios/guided_capture.rb
  - app/services/scenarios/capture.rb
  - extension/content.js
  - app/views/sandbox/postings/show.html.erb
modified_files:
  - extension/content.js
  - extension/manifest.json
  - app/controllers/sandbox/postings_controller.rb
  - app/services/scenarios/reference_diff.rb
  - spec/services/scenarios/reference_diff_spec.rb
  - spec/services/scenarios/guided_capture_spec.rb
  - spec/requests/sandbox_spec.rb
type: enhancement
ordinal: 136000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
## Context

Found by the real-extension browser dogfood of the Reference Comparison drift loop
(wayfinder map doc-6, TASK-118). A real guided `application_execution` session run
through the loaded Chrome extension against `http://wwworkremote.localhost:31000/sandbox/postings/1`
materializes a Scenario whose signatures match `Scenarios::SandboxReferenceWalkthrough`
for every field / screening_question / demographic / commitment_boundary marker — but
**`job_post_id` is never captured**, so every sandbox guided session shows a permanent
`drift/ats_identity job_post_id {change: lost}` finding against the greenhouse reference.

## Root cause

`Scenarios::GuidedCapture#record_ats_ids` matches `Scenarios::Capture::PATTERNS["greenhouse"]`
over `"#{event.page_url}\n#{event.evidence.to_json}"`. For the sandbox:

- `page_url` is `wwworkremote.localhost/sandbox/postings/1?...` — does not match
  `greenhouse\.io/[^/]+/jobs/(\d+)`.
- The `#job_post_id` hidden input on `app/views/sandbox/postings/show.html.erb` (and the
  form's `data-job-post-id`) is not in `application_page_arrived` evidence — `content.js`
  `extractApplicationFormStructure` / `recordGuidedPageArrival` skips `type === 'hidden'`
  and never reads the form data attribute.

So the other greenhouse `job_post_id` pattern (`"job_post_id"\s*:\s*"?(\d+)"?`) has
nothing to match against.

## What to do

Surface `job_post_id` into the `application_page_arrived` evidence from `content.js`:
read `#job_post_id` (value) or the form's `data-job-post-id` when present and add it to
the evidence payload (e.g. `evidence.job_post_id` or a JSON blob the existing pattern
already matches). Keep it provider-neutral — a real Greenhouse form carries the same
hidden field, so this is not sandbox-only glue.

Then re-run `rake scenarios:build_sandbox_reference` if the reference shape shifts, and
re-run the dogfood (`rake scenarios:dogfood:start`) to confirm the `job_post_id` drift
finding is gone.

## Also bump the extension manifest version

Per CLAUDE.md "Chrome extension versioning": any change under `extension/` bumps
`extension/manifest.json`. A new message-payload field is a **minor** bump.

## Related latent issue (fix here or note)

`Scenarios::GuidedCapture` is not idempotent when an event's `approval_state` changes
between materializations: re-running after a pending→approved approval appends a second
`commitment_boundary:<kind>` row (unique index is `(scenario_id, kind, value)`) rather
than replacing the prior value. Benign today — `ReferenceDiff#latest_values` takes the
newest row and coverage/drift math is set-based — but it leaves a contradictory
`=pending` signature in the kind list. Consider replacing prior values for a `(kind,
same source event)` on re-run. The dogfood report task was the only caller that
triggered it early; that path is now read-only, so this is not urgent.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A guided application_execution session run through the loaded extension against the sandbox posting captures a job_post_id signature on the materialized Scenario
- [x] #2 The dogfood comparison (rake scenarios:dogfood:report) shows no `drift/ats_identity job_post_id` finding for a clean sandbox run
- [x] #3 job_post_id extraction reads a hidden field / data attribute generically, not a sandbox-only special case
- [x] #4 extension/manifest.json version bumped (minor) and the reasoning noted in the commit
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Fixed forward in commit `96fc00bf` on branch `reference-comparison-drift-loop`.

**Capture path.** `extension/content.js` gained `extractJobPostId(doc)` — reads
`#application-form input[name="job_post_id"] / #job_post_id` value, falling back to the
form's `data-job-post-id`. No host check. `recordGuidedPageArrival` now includes
`job_post_id` in the `application_page_arrived` evidence, so `Scenarios::GuidedCapture`
records the signature via the existing `Scenarios::Capture::PATTERNS["greenhouse"]`
`"job_post_id":(\d+)` pattern over the evidence JSON.

**Sandbox.** `Sandbox::PostingsController#show` now mints a numeric 10-digit
`job_post_id` (`SecureRandom.random_number(10**10)`) instead of hex — a real Greenhouse
job post id is numeric, and the capture patterns expect `\d+`.

**The real fix.** `Scenarios::ReferenceDiff#changed` now excludes the `ats_identity`
dimension: `job_post_id` / `ats_application_id` values are per-posting / per-application
identifiers that never match between a reference and a candidate, so comparing them by
value only ever produced noise. They are now presence-only (still tracked in
gained/lost). Without this, capturing `job_post_id` would just have converted the
`drift/ats_identity job_post_id lost` finding into a `drift/ats_identity job_post_id
changed` finding on every run.

**Result.** A clean sandbox guided session (paused at the commitment boundary, approved,
completed) now produces exactly one finding — `coverage_gap step:reorientation.2`, the
correct "the run did not submit" signal — and no false `job_post_id` drift. Verified by
end-to-end simulation of the post-fix extension payload + `rake scenarios:dogfood`.

**Manifest.** `extension/manifest.json` 1.28.0 → 1.29.0 (minor: new message-payload
field).

**Not done here (still a note, not urgent):** the `Scenarios::GuidedCapture`
non-idempotency across an `approval_state` flip — re-materializing after pending→approved
appends a second `commitment_boundary:<kind>=approved` row beside the stale `=pending`
one. Benign: `ReferenceDiff#latest_values` takes the newest row and coverage/drift math
is set-based. The only caller that triggered it early (`scenarios:dogfood:report`) is now
read-only. Worth a follow-up if another early-materialize caller appears.
<!-- SECTION:FINAL_SUMMARY:END -->
