---
id: TASK-113
title: Build cross-application question knowledge graph and answer catalog
status: In Progress
assignee:
  - '@claude'
created_date: '2026-08-28 22:51'
updated_date: '2026-08-30 13:59'
labels:
  - application-workflow
  - knowledge-graph
  - analytics
  - human-in-the-loop
dependencies: []
references:
  - TASK-112
  - TASK-66.4
  - TASK-78
documentation:
  - docs/architecture/application-question-knowledge-graph.md
  - docs/adr/008-preserve-question-occurrences-before-archetype-clustering.md
modified_files:
  - CONTEXT.md
  - docs/adr/008-preserve-question-occurrences-before-archetype-clustering.md
  - docs/architecture/application-question-knowledge-graph.md
  - docs/architecture/panoramic-view.md
  - docs/index.md
  - >-
    backlog/tasks/task-113 -
    Build-cross-application-question-knowledge-graph-and-answer-catalog.md
priority: high
type: feature
ordinal: 121000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Turn value-free application question observations into a provenance-preserving learning graph. Keep each observed question occurrence linked to its guided session/application, job posting, company, industry, provider, persona, and outcome; cluster wording variants into reviewable Question Archetypes; attach reusable deterministic, authored, learned, submitted, or AI-assisted answer strategies to archetypes; and visualize frequency, variation, answer sophistication, and outcome relationships across the application corpus. This extends TASK-112's recorder and TASK-66.4/TASK-78's per-posting Q&A without flattening observations into one mutable canned-answer row.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Every observed application question occurrence remains durable and traceable to the guided session or application, job posting, company, industry, provider, persona, page step, and observed wording
- [ ] #2 Question occurrences can be grouped into reviewable Question Archetypes while preserving wording variants and supporting explicit merge, split, and correction decisions
- [ ] #3 Answer candidates and reusable templates attach to archetypes with persona, provenance, source, version, confidence, and deterministic-versus-sophisticated classification
- [ ] #4 A graph/map view shows the most common archetypes and their relationships to applications, companies, industries, providers, personas, answers, and outcomes
- [ ] #5 The system recommends canned or more sophisticated answer handling from evidence and confidence but does not silently promote, overwrite, fill, or submit answers
- [ ] #6 Existing ApplicationQuestion, ApplicationFieldObservation, and ApplicationAnswerTemplate data has an explicit migration/backfill and compatibility plan
- [ ] #7 Focused tests and a repeatable sandbox walkthrough prove duplicate observations aggregate without losing per-application provenance
<!-- AC:END -->

## Comments

<!-- COMMENTS:BEGIN -->
author: Codex
created: 2026-08-28 22:52
---
Domain and architecture captured. Canonical split: Question Occurrence preserves exact per-application evidence; Question Archetype is a reviewable semantic cluster; Answer Strategy is versioned, persona-aware, and provenance-bearing; Answer Sophistication separates deterministic/profile facts, stable authored responses, and contextual synthesis. Relational tables remain the source of truth, with a graph-shaped read model first; no graph database until traversal or scale evidence justifies it.
---

author: wayfinder
created: 2026-08-29 17:33
---
Wayfinder map doc-7 (link-to-application capture and the datalake), TASK-123 resolved the datalake <-> operational read-model contract. Constraints on this task's implementation:

- The question graph's occurrence/archetype extraction reads raw guided-session assets (DOM bundle) **only through `Datalake::Bundle`** -- never `File.read` on `data/datalake/sessions/<token>/`. The bundle exists only for guided sessions; the four `trace_id`-keyed capture tables (`ApplicationFieldObservation` etc.) stay the primary input and are consumed directly, unchanged.
- Any heavy DOM-parsing extractor is a `Datalake::Extractor` subclass (defines `key` + `version` + `extract(bundle)`).
- Question occurrences persist into this task's own tables, each stamped with a `datalake_extractor_version`; a mismatch on read triggers re-extraction (ADR-009 `comparison_rules_version` discipline). No shared `datalake_extractions` cache table.
- Cadence: cheap structural signatures already come from `Scenarios::GuidedCapture` on `complete!` (value-free event evidence). Richer occurrence extraction that needs the DOM is enqueued on first read, with a 'still extracting' state on the view -- not synchronous in-request, not an eager job on `complete!`.
- No second correlation key: `session_token` is the spine for guided-session-derived data; `trace_id` / `application_trace_id` keep their existing non-guided meaning.

Separately: TASK-124 (map doc-7) will attach the per-archetype automation-readiness class (`deterministic` / `generatable` / `needs-human`) and the accept/edit/decline verdict corpus to the archetype model built here.
---

author: wayfinder
created: 2026-08-29 18:45
---
Wayfinder map doc-7, TASK-124 resolved the automation-readiness loop that attaches to the archetype model this task builds. Implementation is TASK-127 (depends on this task). What TASK-127 adds on top of the archetype:
- append-only `archetype_readiness_assessments` (archetype_id, readiness_class [deterministic|generatable|needs_human], rationale, assessed_by, assessed_at, source_assessment_id) -- FindingDisposition-style; latest applicable wins; merge/split carries forward as a suggestion.
- value-free `answer_proposal_verdicts` (archetype_id, occurrence_id, persona_id, provider, strategy_source, proposed_text_sha256, final_text_sha256, edit_distance, verdict, decided_at).
- the archetype review UI (this task's AC#4/#5) shows a suggested readiness class per archetype; TASK-127 owns that suggestion's inputs (frequency, winning strategy source, median edit distance, sample-size floor).
Keep the archetype merge/split operations (this task's AC#2) aware that a readiness assessment may need to carry forward as a suggestion when they run.
---
<!-- COMMENTS:END -->
