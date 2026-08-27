---
id: TASK-102
title: Build the Scenario capture path (nothing records a session into one yet)
status: To Do
assignee: []
created_date: '2026-08-27 17:24'
updated_date: '2026-08-27 17:26'
labels:
  - architecture
  - signature-registry
dependencies: []
documentation:
  - docs/architecture/signature-registry.md
  - docs/architecture/panoramic-view.md
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
- [ ] #1 A HAR or DOM capture can be turned into a real Scenario + ScenarioSignature rows via a repeatable, testable path (script, service, or controller action -- implementer's call, documented reasoning either way)
- [ ] #2 Scenarios::HandshakeCheck.call(scenario) returns real, correct results against a Scenario built this way
- [ ] #3 Does not modify Applications::RowImporter or its subclasses
- [ ] #4 Spec coverage proving the capture path is idempotent (re-running against the same source doesn't duplicate ScenarioSignature rows -- the existing unique index should make this straightforward to prove)
- [ ] #5 Captures resume_persona_id on the Scenario when a real persona was in play (decided 2026-08-27 -- Scenario#resume_persona_id, nullable, mirrors UserJobPosting#resume_persona_id; a verification-only sandbox capture may legitimately have none)
<!-- AC:END -->
