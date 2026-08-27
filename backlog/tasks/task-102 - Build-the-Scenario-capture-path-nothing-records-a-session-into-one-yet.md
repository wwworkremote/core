---
id: TASK-102
title: Build the Scenario capture path (nothing records a session into one yet)
status: Done
assignee: []
created_date: '2026-08-27 17:24'
updated_date: '2026-08-27 18:20'
labels:
  - architecture
  - signature-registry
dependencies: []
documentation:
  - docs/architecture/signature-registry.md
  - docs/architecture/panoramic-view.md
modified_files:
  - app/services/scenarios/capture.rb
  - spec/services/scenarios/capture_spec.rb
  - db/migrate/20260827180000_add_resume_persona_to_scenarios.rb
  - db/schema.rb
  - app/models/scenario.rb
  - app/models/scenario_signature.rb
  - spec/models/scenario_spec.rb
  - spec/models/scenario_signature_spec.rb
  - spec/factories/scenarios.rb
  - spec/factories/scenario_signatures.rb
  - docs/architecture/signature-registry.md
priority: high
type: feature
ordinal: 100
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Foundational piece all the other Signature Registry / Sandbox Provider tasks depend on. `Scenario`/`ScenarioSignature`/`Scenarios::HandshakeCheck` exist (built 2026-08-27) but nothing writes a real `ScenarioSignature` row yet -- there's no path from "a HAR/DOM capture happened" to "a Scenario exists with signatures on it."

Read first: docs/architecture/signature-registry.md (the whole doc, especially "Three things, not one" and "Reference Scenario"), docs/architecture/panoramic-view.md (the deferred raw-capture item this may reuse).

Shape to follow, same pattern Applications::RowImporter already established for the three existing backfill importers (app/services/applications/row_importer.rb + its 3 subclasses): a parser that reads a HAR or DOM capture, extracts one signature per externally-observed identity (job id, ats_application_id, session_cookie, etc. -- see Scenarios::HandshakeCheck::SIGNATURE_EXPECTATIONS for the known kinds per provider), and writes them via Scenario.create! + scenario.scenario_signatures.create! (append-only, unique on scenario_id+kind+value -- already enforced at the DB level).

Do NOT touch Applications::RowImporter or the routine LinkedIn/Greenhouse/Indeed backfill path -- Scenario is explicitly scoped to deliberate verification captures only (decided 2026-08-27, see signature-registry.md's "Decided" section). This is a new, separate capture path, not a change to the existing one.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A HAR or DOM capture can be turned into a real Scenario + ScenarioSignature rows via a repeatable, testable path (script, service, or controller action -- implementer's call, documented reasoning either way)
- [x] #2 Scenarios::HandshakeCheck.call(scenario) returns real, correct results against a Scenario built this way
- [x] #3 Does not modify Applications::RowImporter or its subclasses
- [x] #4 Spec coverage proving the capture path is idempotent (re-running against the same source doesn't duplicate ScenarioSignature rows -- the existing unique index should make this straightforward to prove)
- [x] #5 Captures resume_persona_id on the Scenario when a real persona was in play (decided 2026-08-27 -- Scenario#resume_persona_id, nullable, mirrors UserJobPosting#resume_persona_id; a verification-only sandbox capture may legitimately have none)
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Built Scenarios::Capture (app/services/scenarios/capture.rb), a service -- not a bin/ script or controller action -- because AC#4's idempotency proof needs the write path to be directly unit-testable against constructed HAR/DOM fixtures, matching how Applications::RowImporter's own write half is spec-covered while its HAR-to-row extraction stays in untested bin/ scripts. This service does both halves in one class: it extracts every ScenarioSignature kind SIGNATURE_EXPECTATIONS names for the given provider directly from a raw HAR or saved-DOM string via a PATTERNS regex table (base64-decoding HAR response bodies the same way bin/import_greenhouse_applications already does), then writes Scenario.create! + scenario.scenario_signatures.find_or_create_by! (append-only, no destructive corrections).

Idempotency (AC#4): callers pass the same Scenario back in via `scenario:` for a re-run against the same source; find_or_create_by!(kind:, value:) scoped to that scenario means an identical (kind, value) is a no-op (proven: "is idempotent" spec, 0 new ScenarioSignature rows on rerun), while a genuinely changed value under the same kind is correctly recorded as a new row per the append-only convention (proven: "records a changed value... as a new row" spec).

resume_persona_id (AC#5): added via migration 20260827180000_add_resume_persona_to_scenarios.rb (nullable string, mirrors UserJobPosting's column exactly, no FK -- UserJobPosting's own resume_persona_id isn't an FK either). Capture forwards it through a scenario_attrs: hash to Scenario.create! when building a new Scenario; proven present when passed and nil when a real persona wasn't in play (verification-only case), matching signature-registry.md's stated rule.

HandshakeCheck correctness (AC#2): two specs run Scenarios::HandshakeCheck.call against a Scenario built via Scenarios::Capture -- one where the HAR contains a real LinkedIn job id (required-and-present) and one where it doesn't (required-and-missing) -- both assert the exact real result, not a stub.

RowImporter (AC#3): confirmed via git status that no file under app/services/applications/ changed.

Judgment call: PATTERNS' regexes for ats_application_id, candidate_id, and tenant_id are inferred from this codebase's existing RowImporter URL/field conventions plus Workday's publicly documented hostname shape -- there's no real captured sample for any of them yet (a genuine gap this task can't close without one). Marked with a ponytail: comment in the source naming this as the ceiling; the doc's own "Reference Scenario" phase-2 process (a real capture confirming or correcting the pattern) is the intended way this gets tightened, not a guess frozen in place. job_id/job_post_id/job_key patterns are the exact URL shapes RowImporter's native_id_fragment already uses, so those have real prior-art backing.

Also updated docs/architecture/signature-registry.md's status line and its "what exists vs. deferred" table row for raw-capture, since it was already tracking this exact gap and TASK-102 closes it.

Verified: bundle exec rspec spec/services/scenarios/capture_spec.rb spec/services/scenarios/handshake_check_spec.rb spec/models/scenario_spec.rb spec/models/scenario_signature_spec.rb -- 31 examples, 0 failures. Did not run the full suite per TASK-110's concurrent test-DB usage. rubocop clean on all touched files.
<!-- SECTION:FINAL_SUMMARY:END -->
