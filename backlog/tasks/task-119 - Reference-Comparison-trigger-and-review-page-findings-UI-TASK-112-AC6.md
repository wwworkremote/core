---
id: TASK-119
title: Reference Comparison trigger and review-page findings UI (TASK-112 AC#6)
status: Done
assignee:
  - '@claude'
created_date: '2026-08-29 00:21'
updated_date: '2026-08-29 03:10'
labels:
  - architecture
  - application-workflow
  - reference-comparison
  - human-in-the-loop
dependencies:
  - TASK-116
  - TASK-117
  - TASK-118
documentation:
  - docs/adr/009-reference-comparison-drift-and-coverage.md
  - docs/architecture/guided-session-flow.md
  - docs/architecture/signature-registry.md
  - app/models/guided_session.rb
  - app/views/guided_sessions/show.html.erb
modified_files:
  - app/models/guided_session.rb
  - app/models/comparison_finding.rb
  - app/controllers/guided_sessions_controller.rb
  - config/routes.rb
  - app/views/guided_sessions/show.html.erb
  - app/views/guided_sessions/_reference_comparison.html.erb
  - spec/requests/guided_sessions_spec.rb
  - docs/architecture/signature-registry.md
  - docs/architecture/guided-session-flow.md
priority: high
type: feature
ordinal: 135000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Per ADR 009. Wires the comparison engine (TASK-116) and records (TASK-117) to the guided session lifecycle and review page, and closes TASK-112 AC#6 ('The recorded session is visible in the local app and can be compared with the provider Reference Scenario'). Depends explicitly on TASK-116 (engine), TASK-117 (records) and TASK-118 (a usable structural reference) — its acceptance exercises all three seams.

Scope:
- Automatic trigger: when a GuidedSession first transitions to completed, run a ReferenceComparison. The trigger is idempotent for that transition — retries or repeated transitions must not create duplicate 'automatic' runs.
- Manual trigger: a 'Compare to Reference' action on the guided session review page creates a new ReferenceComparison run every time it is invoked.
- The comparison is advisory and presentational only. It must never authorize, block, advance, or submit an application, and must not change the session phase, status, or playback position. Mirror the existing playback-cursor 'viewing not authorization' separation.
- Review page presentation:
  - the coverage phase/step map (reached / not reached / not applicable), not just a percentage; 'unavailable' shown as such
  - the drift findings for the run, each with its dimension and locator
  - for each finding, the disposition control with the five values, showing any carried-forward suggestion (and its source) as a default that still requires explicit confirmation
  - prior runs for the session remain viewable (immutable history)
- If a real provider is not involved and no reference exists for the provider, the page states that plainly rather than erroring.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A GuidedSession transitioning to completed for the first time automatically creates exactly one ReferenceComparison; a repeated or retried completed transition creates no additional automatic run (idempotent) — proven by a spec
- [x] #2 The 'Compare to Reference' review-page action creates a new immutable ReferenceComparison run on each invocation — proven by a spec
- [x] #3 Neither the automatic nor the manual path changes session phase, status, playback position, or authorizes/advances/submits an application — proven by a spec asserting session state is unchanged across a comparison
- [x] #4 The review page renders the coverage phase/step map with reached / not reached / not applicable states and shows 'unavailable' when there are zero applicable checkpoints
- [x] #5 The review page lists the run's drift findings with dimension and locator, and offers a disposition control with the five values per finding
- [x] #6 A carried-forward disposition appears as a labelled suggestion with its source, and the finding is not considered dispositioned until the reviewer confirms
- [x] #7 Prior comparison runs for the session remain viewable as immutable history
- [x] #8 When no Reference Scenario exists for the provider, the page says so instead of raising
- [x] #9 TASK-112 AC#6 is checked; guided-session request spec coverage for the trigger, the advisory-only guarantee, and the findings/disposition rendering
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Research

- Guided session has `status` (active/paused/completed/stopped) but nothing transitions it to `completed` today — this task adds the transition + trigger.
- `GuidedSessionsController` + `app/views/guided_sessions/show.html.erb` (Tailwind/DaisyUI dark, `card-neural`). Routes: `resources :guided_sessions, only: %i[new create show]` with a `member` block.
- Single admin (HTTP basic, no `current_user`); reviewer = `ENV.fetch("ADMIN_EMAIL", "mike@just3ws.com")`, `reviewer_label: "Mike"`.
- `Scenarios::RecordComparison.call(session, trigger:)` (TASK-117) already handles no_reference/failed internally.

## Approach

**Model — `GuidedSession`:**
- `has_many :reference_comparisons, dependent: :destroy`.
- `#complete!` — no-op if already `completed`; else `update!(status: "completed")` then `run_automatic_comparison`.
- `#run_automatic_comparison` — guard `return if reference_comparisons.exists?(trigger: "automatic")`; `Scenarios::RecordComparison.call(self, trigger: "automatic")` wrapped in `rescue StandardError` + `Rails.logger.warn` (advisory — a comparison failure never breaks completion).
- `#latest_comparison` — `reference_comparisons.order(:ran_at, :id).last`.

**Controller — 3 actions (member):**
- `complete` (POST) → `@guided_session.complete!` → redirect with notice. Never changes phase/playback.
- `compare` (POST) → `Scenarios::RecordComparison.call(@guided_session, trigger: "manual")` → redirect. New run every call.
- `create_disposition` (POST `findings/:finding_id/dispositions`) → find the finding scoped to this session's comparisons; `finding.finding_dispositions.create!(value:, rationale:, reviewer:, reviewer_label:, source_disposition_id: finding.suggested_disposition_id if value matches the suggestion)` → redirect.

**Routes:** add `post :complete`, `post :compare`, `post "findings/:finding_id/dispositions" => "guided_sessions#create_disposition", as: :finding_dispositions` inside the existing `member` block.

**View — new `_reference_comparison.html.erb` partial, rendered in `show`:**
- "Complete session" (unless completed) + "Compare to Reference" buttons.
- `latest_comparison`: outcome badge. `no_reference` → "No reference scenario for <provider> yet." `failed` → the error. `ok`:
  - coverage: the per-checkpoint phase/step map (reached / not reached / not applicable badges) or "Coverage unavailable"; ratio shown as a derived secondary number.
  - drift findings: each with category + dimension + locator + `detail`; the `current_disposition` (if any); a `<select>` of the 5 values + rationale textarea + submit; the `suggested_disposition` shown as a labelled default ("Last time: …") that still needs confirmation.
- prior runs: compact list (ran_at, trigger, outcome, finding count) — immutable history.
- No reference at all → the "no reference" line, no raise.

## Specs — `spec/requests/guided_sessions_spec.rb` (extend)
- completing a session the first time creates exactly one automatic `ReferenceComparison`; completing again (or re-POST) creates no second automatic run.
- the compare action creates a new `manual` run each call.
- neither path changes `phase` / `playback_position` / authorizes anything (assert session state stable across a compare).
- review page renders the coverage map + a drift finding + a disposition control; a carried-forward suggestion is labelled and the finding stays undispositioned until the form is submitted.
- no `ReferenceScenario` for the provider → page shows the "no reference" message, HTTP 200.

## Verify
`bundle exec rspec spec/requests/guided_sessions_spec.rb spec/models spec/services/scenarios spec/requests/docs_spec.rb` + rubocop. Bump `extension/manifest.json`? No — no `extension/` change. Check TASK-112 AC#6, update `guided-session-flow.md` / `signature-registry.md` rows.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Model: GuidedSession has_many :reference_comparisons; #complete! (no-op if already completed) sets status then #run_automatic_comparison (guarded by `reference_comparisons.exists?(trigger: "automatic")`, rescued -- a comparison failure never blocks completion, never touches phase/playback). #latest_comparison. ComparisonFinding#current_disposition switched to Ruby-side max_by so the review page's eager-load is actually used (Bullet).

Controller: 3 member actions -- complete (POST), compare (POST -> RecordComparison trigger: "manual", new run each call), create_disposition (POST findings/:finding_id/dispositions -> finding scoped to this session's comparisons; source_disposition_id recorded only when the submitted value equals the carried-forward suggestion). reviewer = ENV ADMIN_EMAIL, reviewer_label "Mike".

View: app/views/guided_sessions/_reference_comparison.html.erb rendered from show. Branches: no comparison / no_reference (names the provider, no raise) / failed (shows error) / ok (coverage phase-step map with reached|not_reached|not_applicable badges + "unavailable"; drift findings with category/dimension/locator/detail; per-finding 5-value select + rationale; carried-forward suggestion shown as a labelled default that still needs confirmation). Prior runs in a <details>. `.includes(:suggested_disposition, :finding_dispositions)` to satisfy Bullet.

Verification:
- spec/requests/guided_sessions_spec.rb "reference comparison" -- 7 new examples: one-automatic-run-on-first-completion + none-on-repeat; new-manual-run-per-compare + no phase/status/playback change; coverage map + drift finding + disposition control render; carried-forward suggestion shown, finding undispositioned; disposition recorded from the page; no-reference message + no raise.
- Full spec/models + spec/services/scenarios + guided/api/docs/sandbox -> 285 examples, 0 failures. docs_spec 7/0. RuboCop + erb_lint clean.

Note: TASK-118 (rebuild the sandbox greenhouse Reference Scenario via a real execution guided session) is the remaining live-dogfood verification -- the mechanism here is fixture-tested end to end and handles the no-reference case gracefully until then.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
## What changed

Closes the Reference Comparison drift loop and **TASK-112 AC#6** — the recorded guided session is now visible in the app and compared against its provider Reference Scenario.

### Trigger
- `GuidedSession#complete!` — transitions to `completed` and runs **one idempotent automatic** `ReferenceComparison` (guarded by an existing automatic run; a comparison failure is rescued and never blocks completion; phase/playback untouched).
- `POST /guided_sessions/:id/compare` — a **new manual run every invocation**.
- `POST /guided_sessions/:id/findings/:finding_id/dispositions` — records a `FindingDisposition`; `source_disposition_id` is set only when the chosen value equals the carried-forward suggestion.

### Review page (`_reference_comparison.html.erb`)
- Coverage phase/step map — `reached` / `not_reached` / `not_applicable` badges, `unavailable` when there are no applicable checkpoints.
- Drift findings — category, dimension, `locator`, detail; a per-finding 5-value disposition `<select>` + rationale.
- A carried-forward suggestion renders as a labelled default ("Suggested from an earlier run … not applied; confirm below") — the finding stays undispositioned until submitted.
- Prior runs in a `<details>` (immutable history).
- No `ReferenceScenario` for the provider → names the provider and says so; never raises.
- Advisory only — no path changes phase, status (beyond `complete!` itself), playback, or authorizes/advances an application.

`ComparisonFinding#current_disposition` moved to a Ruby-side `max_by` so the page's eager-load is honoured (Bullet).

## Tests
`spec/requests/guided_sessions_spec.rb` — 7 new examples covering every AC. Full `spec/models` + `spec/services/scenarios` + guided/api/docs/sandbox → **285 examples, 0 failures**. `docs_spec` 7/0. RuboCop + erb_lint clean.

## Follow-up
**TASK-118** — rebuild the sandbox Greenhouse Reference Scenario from a real execution guided session (needs a browser dogfood). Until then the loop is fixture-verified end to end and degrades gracefully to the no-reference message. That is the only remaining ticket on the drift-loop map.
<!-- SECTION:FINAL_SUMMARY:END -->
