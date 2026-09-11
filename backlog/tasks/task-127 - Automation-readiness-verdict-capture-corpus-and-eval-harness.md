---
id: TASK-127
title: 'Automation-readiness: verdict capture, corpus, and eval harness'
status: Done
assignee: []
created_date: '2026-08-29 18:44'
updated_date: '2026-08-30 14:48'
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
- [x] #1 archetype_readiness_assessments append-only table exists; a reader returns the latest applicable assessment per archetype; an archetype merge/split carries the prior assessment forward as a labelled suggestion, never silently as fact
- [x] #2 answer_proposal_verdicts table exists and is value-free (sha256 hashes + edit_distance, no answer text); a migration/backfill plan for any existing ai->submitted history is included or explicitly declined with reason
- [x] #3 The answer-proposal flow (sidepanel TASK-78 path + any server-side LLM::AnswerGenerator caller) writes exactly one answer_proposal_verdict per proposal shown, including declines
- [x] #4 The archetype review UI shows a suggested readiness-class default computed from occurrence frequency, historically-winning strategy source, historical median edit distance, and a sample-size floor (< N verdicts => needs_human); Mike sets the actual class; the suggestion is never auto-applied
- [x] #5 rake automation_readiness:corpus writes per-archetype JSONL to data/datalake/corpus/ (git-ignored), one line per verdict plus the strategy that produced the proposal
- [x] #6 rake automation_readiness:eval replays LLM::AnswerGenerator.call per archetype with >= N verdicts against a representative occurrence, and reports verbatim-acceptance rate + median edit distance split by strategy_source; it writes an advisory report only, no DB write, no answer filled or submitted
- [x] #7 A test asserts no code path consumes a readiness class or eval score to fill or submit an answer without an explicit Mike action
- [x] #8 data/datalake/corpus/ is covered by .gitignore and never committed or synced
- [x] #9 CONTEXT.md gains 'Automation Readiness' and 'Answer Proposal Verdict' glossary entries
- [x] #10 The readiness loop is documented in the datalake architecture doc / ADR that wayfinder map doc-7 produces
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Built the automation-readiness loop on top of the TASK-113 Question Archetype. Pushed to main (`53c704a7`..`3f0326ec` — landed directly on main, no feature branch, my miss). Full suite 1092 examples / 0 failures.

**Tables** (`CreateAutomationReadiness`)
- `archetype_readiness_assessments` — append-only, FindingDisposition-style. `ArchetypeReadinessAssessment.current_for(archetype)` returns the latest; `readonly?` blocks overwrites. `QuestionArchetypes::Merge` **and** `::Split` carry the prior assessment forward onto the target / split-off archetype as an `assessed_by: "merge:carry_forward"` suggestion (AC#1).
- `answer_proposal_verdicts` — value-free: sha256 digests + `edit_distance` + `strategy_source` (`canned`/`template`/`ai`) + `verdict` (`accepted`/`edited`/`declined`), never answer text. A model validation rejects non-64-hex values in the hash columns (AC#2). No backfill of historical `ai`→`submitted` answers — declined and documented: the proposal text is gone, so no value-free verdict can be reconstructed.

**Verdict capture** (AC#3)
- `AnswerProposalVerdicts::Record.for_generated` — `LLM::AnswerGenerator#apply_answer` writes a `declined` row the moment a proposal is shown (covers the per-posting Q&A **and** the sidepanel "Generate answer" path, which both route through `AnswerGenerator`).
- `.resolve` — `Api::V0::ApplicationStatusesController#capture_answers` flips the open row to `accepted`/`edited` with a real `DidYouMean::Levenshtein` distance when the submitted answers arrive (both texts in hand only there).
- `POST /api/v0/answer_proposal_verdicts` + `AnswerProposalVerdicts::Record.from_fill` — the sidepanel template-fill path; server hashes and discards the text. `sidepanel.js` posts on a template Fill; `manifest.json` 1.31.0 → 1.32.0.

**Suggested default** (AC#4) — `QuestionArchetypes::SuggestedReadiness` from verdict sample size (< 5 → `needs_human`), verbatim-acceptance rate, median edit distance, and question kind. Shown on the archetype show page with a set-readiness form (append-only); carried-forward assessments are labelled "confirm".

**Corpus + eval**
- `AutomationReadiness::CorpusExporter` / `rake automation_readiness:corpus` (AC#5) — per-archetype JSONL under `data/datalake/corpus/` (git-ignored, verified — AC#8).
- `AutomationReadiness::Eval` / `rake automation_readiness:eval` (AC#6) — acceptance rate + median edit distance split by `strategy_source` per archetype over the floor, plus a `LLM::AnswerGenerator.call` replay in a **rolled-back transaction**. Advisory report to `eval_report.json`, no DB write, no answer filled or submitted.

**Guardrail** (AC#7) — a model spec asserts no `app/**/*.rb` file both writes an answer and reads a readiness signal.

**Docs** (AC#9/#10) — `CONTEXT.md` gains "Automation Readiness" + "Answer Proposal Verdict"; `datalake.md` and `application-question-knowledge-graph.md` document the built loop.

**Note:** TASK-127's 4 commits landed directly on `main` (I forgot to branch after the TASK-113 merge). Result is clean, green, and pushed; flagged so history is understood.
<!-- SECTION:FINAL_SUMMARY:END -->
