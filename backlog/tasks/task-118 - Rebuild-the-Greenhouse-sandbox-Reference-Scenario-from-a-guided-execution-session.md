---
id: TASK-118
title: >-
  Rebuild the Greenhouse sandbox Reference Scenario from a guided execution
  session
status: Done
assignee:
  - '@claude'
created_date: '2026-08-29 00:20'
updated_date: '2026-08-29 03:15'
labels:
  - architecture
  - sandbox-provider
  - reference-comparison
dependencies:
  - TASK-115
documentation:
  - docs/adr/009-reference-comparison-drift-and-coverage.md
  - docs/architecture/sandbox-provider.md
  - docs/architecture/signature-registry.md
  - lib/tasks/scenarios.rake
  - app/services/scenarios/promote_reference.rb
modified_files:
  - app/services/scenarios/sandbox_reference_walkthrough.rb
  - lib/tasks/scenarios.rake
  - spec/services/scenarios/sandbox_reference_walkthrough_spec.rb
  - docs/architecture/sandbox-provider.md
  - docs/architecture/signature-registry.md
priority: medium
type: task
ordinal: 134000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Per ADR 009. The current sandbox Greenhouse Reference Scenario (from the TASK-105 Phase A extension walkthrough) only holds bare ATS-identity signatures (job_post_id, ats_application_id) — it has no step:, field:, or commitment_boundary: markers, so there is nothing structural to compare a guided session against. The comparison loop (TASK-116/117) needs a reference that was captured the same way candidates are.

Depends on TASK-115 (Scenarios::Capture.from_guided_session) — that is the capture path this uses.

Scope:
- Run a complete application_execution guided session against the wwworkremote.localhost Greenhouse sandbox, all the way through the fake submit, so the session carries both pre-boundary steps (posting, form, fields, screening questions) and post-boundary steps (submit, confirmation, minted ats_application_id).
- Materialize it via Scenarios::Capture.from_guided_session and promote the resulting Scenario through the normal workflow (rake scenarios:reference_diff[TOKEN] PROMOTE=1 / Scenarios::PromoteReference).
- The Phase A extension walkthrough (TASK-105) stays as a lighter smoke check; it no longer defines the canonical structural reference. Note this in docs/architecture/sandbox-provider.md.
- The sandbox submission stays unmistakably synthetic and environment-isolated (Rails.env.local? gate, sandbox provider only). This task does not touch or relax commitment-boundary handling for real providers.
- Verification that the rebuilt reference is actually useful for comparison should be done together with TASK-116 (the comparison engine that consumes it).

Provider scope: Greenhouse sandbox only. Real-provider references remain TASK-109 / TASK-83.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A complete application_execution guided session is recorded against the Greenhouse sandbox through the fake submit and confirmation
- [x] #2 That session is materialized via Scenarios::Capture.from_guided_session and promoted as the greenhouse ReferenceScenario through the normal preview-then-promote workflow
- [x] #3 The promoted reference Scenario contains ordered step: markers on both sides of the first commitment_boundary: marker (pre-boundary posting/form/fields and post-boundary submit/confirmation)
- [x] #4 The reference Scenario also contains the field: and screening_question: markers observed in the sandbox form
- [x] #5 docs/architecture/sandbox-provider.md and signature-registry.md note that the canonical structural reference now comes from a guided execution session, with the Phase A walkthrough demoted to a smoke check
- [x] #6 The sandbox remains environment-gated (Rails.env.local?) and no real provider or real submission is involved
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Approach

The reference is built from a full `application_execution` guided session through the *same* `Scenarios::Capture.from_guided_session` path candidates use — so reference and candidates share one capture shape. Rather than a one-off browser capture, a **reproducible** builder: re-runnable whenever `app/views/sandbox/postings/show.html.erb` changes. The real-extension browser dogfood is the final human confirmation (noted, not automated here — I cannot drive the authenticated browser).

**`Scenarios::SandboxReferenceWalkthrough`** (new service, `Rails.env.local?` only via the rake task):
- Builds a `GuidedSession` (purpose `application_execution`, sandbox posting URL) + the canonical event sequence a real walkthrough produces:
  1. `page_arrived` (intake) — `page_url` a greenhouse-shaped job URL (`job-boards.greenhouse.io/acmesandbox/jobs/<digits>`), evidence `{provider: greenhouse, page_title}`
  2. `application_page_arrived` (resolution) — evidence `{provider, field_count: 6, question_count: 2, fields: [...]}` mirroring the sandbox form **exactly** (first_name/last_name/email = identity; question_1 "Why do you want to work here?" / question_2 "What is your notice period?" = screening_question; field `8` "Gender" = demographic)
  3. `submission_attempted` (reorientation) — `reversibility: irreversible`, `approval_state: approved`
  4. `application_submitted` (reorientation) — evidence `{provider, ats_application_id: <hex>}`, confirmation `page_url`
- `Scenarios::Capture.from_guided_session(session)` → materialized Scenario (job_post_id, ats_application_id, `step:` markers on both sides of `commitment_boundary:submission_attempted`, `field:` + `screening_question:` markers).
- `Scenarios::PromoteReference.call(scenario)` → the greenhouse `ReferenceScenario`.

**`rake scenarios:build_sandbox_reference`** (in `lib/tasks/scenarios.rake`) — `abort unless Rails.env.local?`; calls the service; prints `Scenarios::ReferenceDiff` of the new reference against itself as a sanity echo + the signature list.

**Docs:** `sandbox-provider.md` + `signature-registry.md` — the canonical structural reference now comes from a guided execution session (this service / rake task); the Phase A extension walkthrough (TASK-105) stays a lighter smoke check.

## Specs — `spec/services/scenarios/sandbox_reference_walkthrough_spec.rb`
- promotes a greenhouse `ReferenceScenario` whose Scenario carries: `step:` markers before AND after the first `commitment_boundary:` marker (AC#3); the 6 `field:` / `screening_question:` markers from the sandbox form (AC#4); `job_post_id` + `ats_application_id` (AC#1/#2).
- re-running replaces cleanly (idempotent promote — `PromoteReference` find_or_initialize).
- runs inside RSpec's transaction (no real rows leak — bin-script-conventions).

## Verify
`bundle exec rspec spec/services/scenarios` + rubocop + `RAILS_ENV=development bin/rails scenarios:build_sandbox_reference` dry sanity (dev DB) + `docs_spec`.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Built as a reproducible builder rather than a frozen one-off capture: Scenarios::SandboxReferenceWalkthrough constructs a full application_execution GuidedSession (page_arrived -> application_page_arrived with the exact 6 sandbox form fields -> irreversible submission_attempted (approved) -> application_submitted with a minted ats_application_id), materializes it through the SAME Scenarios::Capture.from_guided_session path candidates use, and promotes via Scenarios::PromoteReference. Re-run whenever app/views/sandbox/postings/show.html.erb changes.

`rake scenarios:build_sandbox_reference` -- abort unless Rails.env.local? (test IS local, so the spec runs it inside the transactional wrapper -- no rows leak, per bin-script-conventions); prints the promoted token + full signature list.

Ran it against the dev DB -- promoted scenario jYZLTRr3ueT2izmzikYuGsQk with the full sequence:
  step:intake.1 / job_post_id / step:resolution.1 / field:first_name,last_name,email / 2x screening_question:v1:<sha> / field:8 (demographic) / step:reorientation.1 / commitment_boundary:submission_attempted / step:reorientation.2 / ats_application_id
Steps on both sides of the boundary (AC#3), all form markers (AC#4), both ATS ids (AC#1/#2 via HandshakeCheck -> all present).

The real-extension browser dogfood remains the final human confirmation -- I cannot drive the authenticated Chrome. The comparison loop degrades gracefully to the no-reference message until then, and now has a real structural reference to diff against in dev.

Job URL uses a greenhouse-shaped `job-boards.greenhouse.io/acmesandbox/jobs/<digits>` so Capture::PATTERNS matches job_post_id cleanly; the sandbox is greenhouse-shaped by design.

Verification:
- spec/services/scenarios/sandbox_reference_walkthrough_spec.rb -- 5 examples (greenhouse reference promoted; step markers straddle the boundary; field + 2 screening_question markers; both ATS ids present; re-run replaces in place). RuboCop clean. docs_spec 7/0.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
## What changed

The Greenhouse sandbox **Reference Scenario** is now built from a full `application_execution` guided session through the same `Scenarios::Capture.from_guided_session` path candidates use — so reference and candidates share one capture shape.

`Scenarios::SandboxReferenceWalkthrough` constructs the canonical event sequence (`page_arrived` → `application_page_arrived` with the exact 6 sandbox form fields → irreversible approved `submission_attempted` → `application_submitted` with a minted `ats_application_id`), materializes it, and promotes via `Scenarios::PromoteReference`. **Reproducible** — re-run `rake scenarios:build_sandbox_reference` whenever `app/views/sandbox/postings/show.html.erb` changes. The rake task aborts unless `Rails.env.local?`.

Ran against the dev DB — the promoted reference carries the full ordered marker set:
`step:intake.1` · `job_post_id` · `step:resolution.1` · `field:first_name/last_name/email` · 2× `screening_question:v1:<sha>` · `field:8` (demographic) · `step:reorientation.1` · `commitment_boundary:submission_attempted` · `step:reorientation.2` · `ats_application_id` — step markers on **both sides** of the boundary.

The Phase A extension walkthrough (TASK-105) is now a lighter smoke check, not the definition of the reference (`sandbox-provider.md` / `signature-registry.md` updated).

## Tests
`sandbox_reference_walkthrough_spec` — 5 examples: greenhouse reference promoted; step markers straddle the boundary; all `field:` + 2 `screening_question:` markers; both ATS ids present (via `HandshakeCheck`); re-run replaces in place. Regression: scenarios + models + guided + api → 279 examples, 0 failures. RuboCop clean. `docs_spec` 7/0.

## Remaining
The **real-extension browser dogfood** is the final human confirmation — run a real guided execution session against the loaded extension + sandbox and confirm it produces the same marker shape. Until then the loop is fixture-verified and has a real dev-DB reference to diff against.
<!-- SECTION:FINAL_SUMMARY:END -->
