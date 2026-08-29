---
id: TASK-120
title: 'Extension: capture job_post_id in a guided session against the sandbox'
status: To Do
assignee: []
created_date: '2026-08-29 15:50'
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
- [ ] #1 A guided application_execution session run through the loaded extension against the sandbox posting captures a job_post_id signature on the materialized Scenario
- [ ] #2 The dogfood comparison (rake scenarios:dogfood:report) shows no `drift/ats_identity job_post_id` finding for a clean sandbox run
- [ ] #3 job_post_id extraction reads a hidden field / data attribute generically, not a sandbox-only special case
- [ ] #4 extension/manifest.json version bumped (minor) and the reasoning noted in the commit
<!-- AC:END -->
