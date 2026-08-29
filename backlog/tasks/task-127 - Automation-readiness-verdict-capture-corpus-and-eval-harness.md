---
id: TASK-127
title: 'Automation-readiness: verdict capture, corpus, and eval harness'
status: To Do
assignee: []
created_date: '2026-08-29 18:44'
labels:
  - application-workflow
  - knowledge-graph
  - analytics
  - human-in-the-loop
  - datalake
dependencies:
  - TASK-113
references:
  - >-
    backlog/docs/wayfinder/doc-7 -
    Wayfinder-map-link-to-application-capture-and-the-datalake.md
  - >-
    backlog/tasks/task-124 -
    Wayfinder-decision-automation-readiness-corpus-and-eval-harness-shape.md
  - docs/architecture/application-question-knowledge-graph.md
  - app/services/LLM/answer_generator.rb
priority: medium
type: feature
ordinal: 143000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implementation task from wayfinder map doc-7 (backlog/docs/wayfinder/doc-7), shape decided in TASK-124. Depends on TASK-113 (Question Archetype + Question Occurrence models). Measure, per Question Archetype, how ready its answers are to be canned / generated / left to a human -- from Mike's real accept/edit/decline behaviour, not a training run.

DECIDED (do not re-litigate):

- Readiness class lives in an append-only `archetype_readiness_assessments` table: `(archetype_id, readiness_class [deterministic|generatable|needs_human], rationale, assessed_by, assessed_at, source_assessment_id)`. Latest applicable wins for presentation; history is never overwritten. After an archetype merge/split the prior assessment carries forward as a suggestion, not a fact. Mirrors `FindingDisposition` (ADR 009).
- Verdicts are captured in a value-free `answer_proposal_verdicts` table: `(archetype_id, occurrence_id, persona_id, provider, strategy_source [canned|template|ai], proposed_text_sha256, final_text_sha256, edit_distance, verdict [accepted|edited|declined], decided_at)`. Hashes + distance, never the answer text (it already lives in the occurrence / `ApplicationQuestion`). One row per proposal shown, including declines (panel closed without using the proposal).
- "Current rule/template/prompt set" the harness replays through = `CannedAnswers` patterns + `ApplicationAnswerTemplate` rows + `LLM::AnswerGenerator` (its `PromptBuilder` + `SYSTEM_RULES` / `TASK_INSTRUCTIONS` + the configured `answer_generation` model). The harness invokes the same `LLM::AnswerGenerator.call` path.
- Corpus shape: `rake automation_readiness:corpus` writes one git-ignored, machine-local JSONL file per archetype under `data/datalake/corpus/` -- each line a verdict datapoint + the strategy that produced the proposal. Consumed by (a) a human/LLM prompt-authoring session reading it, (b) the eval harness.
- Score: per archetype, verbatim-acceptance rate (headline) + median edit distance (secondary), each split by `strategy_source`. The eval harness reports; a high rate *suggests* a class, Mike sets it.
- Suggested-default formula inputs (name only, weights are implementation detail): occurrence frequency across applications/companies/providers; the historically-winning strategy source; historical median edit distance; a sample-size floor (below N verdicts -> default `needs_human`).
- HARD GUARDRAIL (Bounded Agency): nothing in this system ever uses a readiness class or an eval score to fill or submit an answer without Mike's explicit action. `deterministic` / `generatable` only ever mean "propose without making me think first", never "fill without showing me".

Touches the extension: the sidepanel answer-proposal flow (TASK-78) must record a verdict when Mike accepts / edits / declines a proposal.

OUT OF SCOPE: literal model training / fine-tuning / embeddings on the corpus (map 'Out of scope'); the archetype clustering itself (TASK-113); any auto-fill / auto-submit switch.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 archetype_readiness_assessments append-only table exists; a reader returns the latest applicable assessment per archetype; an archetype merge/split carries the prior assessment forward as a labelled suggestion, never silently as fact
- [ ] #2 answer_proposal_verdicts table exists and is value-free (sha256 hashes + edit_distance, no answer text); a migration/backfill plan for any existing ai->submitted history is included or explicitly declined with reason
- [ ] #3 The answer-proposal flow (sidepanel TASK-78 path + any server-side LLM::AnswerGenerator caller) writes exactly one answer_proposal_verdict per proposal shown, including declines
- [ ] #4 The archetype review UI shows a suggested readiness-class default computed from occurrence frequency, historically-winning strategy source, historical median edit distance, and a sample-size floor (< N verdicts => needs_human); Mike sets the actual class; the suggestion is never auto-applied
- [ ] #5 rake automation_readiness:corpus writes per-archetype JSONL to data/datalake/corpus/ (git-ignored), one line per verdict plus the strategy that produced the proposal
- [ ] #6 rake automation_readiness:eval replays LLM::AnswerGenerator.call per archetype with >= N verdicts against a representative occurrence, and reports verbatim-acceptance rate + median edit distance split by strategy_source; it writes an advisory report only, no DB write, no answer filled or submitted
- [ ] #7 A test asserts no code path consumes a readiness class or eval score to fill or submit an answer without an explicit Mike action
- [ ] #8 data/datalake/corpus/ is covered by .gitignore and never committed or synced
- [ ] #9 CONTEXT.md gains 'Automation Readiness' and 'Answer Proposal Verdict' glossary entries
- [ ] #10 The readiness loop is documented in the datalake architecture doc / ADR that wayfinder map doc-7 produces
<!-- AC:END -->
