---
id: TASK-113
title: Build cross-application question knowledge graph and answer catalog
status: Done
assignee:
  - '@claude'
created_date: '2026-08-28 22:51'
updated_date: '2026-08-30 14:23'
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
- [x] #1 Every observed application question occurrence remains durable and traceable to the guided session or application, job posting, company, industry, provider, persona, page step, and observed wording
- [x] #2 Question occurrences can be grouped into reviewable Question Archetypes while preserving wording variants and supporting explicit merge, split, and correction decisions
- [x] #3 Answer candidates and reusable templates attach to archetypes with persona, provenance, source, version, confidence, and deterministic-versus-sophisticated classification
- [x] #4 A graph/map view shows the most common archetypes and their relationships to applications, companies, industries, providers, personas, answers, and outcomes
- [x] #5 The system recommends canned or more sophisticated answer handling from evidence and confidence but does not silently promote, overwrite, fill, or submit answers
- [x] #6 Existing ApplicationQuestion, ApplicationFieldObservation, and ApplicationAnswerTemplate data has an explicit migration/backfill and compatibility plan
- [x] #7 Focused tests and a repeatable sandbox walkthrough prove duplicate observations aggregate without losing per-application provenance
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

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Built the first implementation of the cross-application question knowledge graph — relational tables + a computed graph-shaped read model, deterministic exact-normalized-prompt clustering, human merge/split (ADR 008 delivery boundary). Merged to main `045194bd`, pushed. Full suite 1072 examples / 0 failures.

**Schema** (`CreateQuestionKnowledgeGraph`)
- `question_occurrences` — immutable per-application evidence. `raw_prompt` + provenance FKs (job_posting, user, user_job_posting, guided_session) + provider/persona/page_step/context; industry via the posting's `data['ai_category']`, outcome via the application. An `on: :update` guard rejects any change to the wording/provenance columns — only the archetype pointer is mutable (AC#1).
- `question_archetypes` — `label` / `canonical_prompt` / `question_kind` / `merged_into` tombstone; `active`/`merged` scopes; `wording_variants` (AC#2).
- `answer_strategies` — `persona_id`, `source` (deterministic/authored/learned/submitted/ai), `sophistication` (deterministic/authored/synthesized), `version`, `confidence`, `enabled`, `provenance` (AC#3).

**Ingest** — `QuestionOccurrences::Record`: an `ApplicationFieldObservation` or a manual `ApplicationQuestion` → a deduped occurrence + exact-prompt archetype assignment (`auto:exact_prompt`, confidence 100). Wired non-blocking into the observations API and `ApplicationQuestion` after_create.

**Backfill** (AC#6) — `QuestionGraph::Backfill` + `rake question_graph:backfill` (re-runnable): backfills history + seeds answer strategies from `ApplicationAnswerTemplate` and submitted `ApplicationQuestion` answers. Existing tables untouched; ran clean on dev data (43 occurrences, 20 archetypes).

**Merge/split** (AC#2) — `QuestionArchetypes::Merge` (repoint occurrences + deduped strategies, tombstone source; TASK-127 hook point noted for readiness carry-forward) and `::Split` (move a strict subset to a fresh archetype). Wording never touched.

**Review surface** (AC#4/#5) — `/question_archetypes` (linked from the profile menu): `QuestionGraph::Overview` ranks archetypes with company/provider spread + coverage gaps; the show page renders occurrences with full provenance, wording variants, strategies, an advisory `QuestionArchetypes::Recommendation` (deterministic/generatable/needs_human from question kind + evidence spread — a sentence, never a switch), and explicit merge/split forms. Request spec asserts the surface never touches `ApplicationFieldAnswer`.

**AC#7** — `spec/services/question_occurrences/record_spec.rb` (aggregation + provenance) + `QuestionGraph::SandboxWalkthrough` / `rake question_graph:sandbox_walkthrough` (records the same 2 questions across 2 throwaway applications, asserts shared archetypes with per-application provenance intact; idempotent).

**Docs** — `application-question-knowledge-graph.md` "Built (TASK-113)" section (component map + deferred: DOM-derived extraction via `Datalake::Bundle`, richer NLP clustering, the readiness/verdict tables which are TASK-127).

**Unblocks TASK-127** (automation-readiness corpus + eval harness), which attaches `archetype_readiness_assessments` + `answer_proposal_verdicts` to the archetype model built here.
<!-- SECTION:FINAL_SUMMARY:END -->
