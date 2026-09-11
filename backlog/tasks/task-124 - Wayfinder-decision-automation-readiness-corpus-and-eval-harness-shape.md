---
id: TASK-124
title: 'Wayfinder decision: automation-readiness corpus and eval-harness shape'
status: Done
assignee:
  - '@claude'
created_date: '2026-08-29 17:24'
updated_date: '2026-08-29 18:44'
labels:
  - 'wayfinder:grilling'
  - application-capture-datalake
  - 'wayfinder-map:doc-7'
dependencies: []
references:
  - >-
    backlog/docs/wayfinder/doc-7 -
    Wayfinder-map-link-to-application-capture-and-the-datalake.md
  - docs/architecture/application-question-knowledge-graph.md
  - >-
    backlog/tasks/task-113 -
    Build-cross-application-question-knowledge-graph-and-answer-catalog.md
  - CONTEXT.md
ordinal: 140000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Decision ticket for wayfinder map doc-7 (backlog/docs/wayfinder/doc-7). Grilling type (HITL) — resolve with Mike via grilling + domain-modeling. Unblocked (frontier).

## Question

What is the automation-readiness decision corpus, physically, and how does the eval harness run against it?

Decided in the map: the readiness unit is the Question Archetype (TASK-113); each carries a `deterministic` / `generatable` / `needs-human` class Mike assigns during review with an evidence-based suggested default; ground truth for evaluation is Mike's recorded accept / edit / decline verdicts; the harness replays archetypes through the current rule/template/prompt set and scores predicted-vs-accepted. No literal model training.

Open for this ticket:
- Where the readiness class and its history live — a column on the archetype, or an append-only `archetype_readiness_assessments` table (mirroring the FindingDisposition append-only pattern)?
- How an accept/edit/decline verdict is captured as a labeled datapoint — a new event table, or a field on the existing answer-proposal flow? What exactly is stored (proposed text hash, accepted text hash, edit distance, archetype, persona, provider, timestamp) — value-free where possible.
- The corpus export shape — per-archetype JSONL, a queryable view, a rake report? Consumed by whom (a future prompt-authoring session, an eval CI job)?
- What the harness's "current rule/template/prompt set" is concretely — `ApplicationAnswerTemplate` rows plus a prompt registry? Where the prompts live.
- The score that matters — exact-match rate, edit-distance delta, precision on "safe to auto-fill"? And the guardrail: a high score never flips an archetype to auto-fill without Mike (Bounded Agency).
- The suggested-default formula inputs (frequency, answer-strategy provenance, historical edit distance) — enough to name; exact weights are implementation detail.

Output: the corpus + harness shape recorded on the map; a note on TASK-113 that readiness assessment attaches here.
<!-- SECTION:DESCRIPTION:END -->

## Comments

<!-- COMMENTS:BEGIN -->
author: wayfinder
created: 2026-08-29 18:44
---
RESOLVED (grilling, 1 round). The automation-readiness corpus + eval harness:

- **Readiness class storage**: append-only `archetype_readiness_assessments` (archetype_id, readiness_class [deterministic|generatable|needs_human], rationale, assessed_by, assessed_at, source_assessment_id). Latest applicable wins for presentation; history never overwritten; merge/split carries forward as a suggestion. Mirrors `FindingDisposition` (ADR 009).
- **Verdict capture**: value-free `answer_proposal_verdicts` (archetype_id, occurrence_id, persona_id, provider, strategy_source [canned|template|ai], proposed_text_sha256, final_text_sha256, edit_distance, verdict [accepted|edited|declined], decided_at). One row per proposal shown, declines included. Hashes + distance only -- no answer text.
- **Harness input** (resolved inline): the 'current rule/template/prompt set' = `CannedAnswers` patterns + `ApplicationAnswerTemplate` rows + `LLM::AnswerGenerator` (`PromptBuilder` + `SYSTEM_RULES`/`TASK_INSTRUCTIONS` + configured `answer_generation` model). The harness calls the same `LLM::AnswerGenerator.call` path.
- **Corpus**: `rake automation_readiness:corpus` -> per-archetype JSONL under `data/datalake/corpus/` (git-ignored, machine-local). One line per verdict + the strategy that produced it. Consumers: a human/LLM prompt-authoring session, and the eval harness.
- **Score + guardrail**: per archetype, verbatim-acceptance rate (headline) + median edit distance (secondary), split by strategy_source. Reported, not enforced -- a high rate suggests a class, Mike sets it. HARD GUARDRAIL: nothing uses a readiness class or eval score to fill or submit without Mike's explicit action; deterministic/generatable = 'propose without making me think first', never 'fill without showing me'.
- **Suggested-default inputs** (resolved inline, weights are impl detail): occurrence frequency across applications/companies/providers; historically-winning strategy source; historical median edit distance; sample-size floor (< N verdicts -> needs_human).

Implementation is **[TASK-127](task-127)** (depends on TASK-113), 10 ACs, touches the extension (sidepanel TASK-78 verdict hook). Note added to TASK-113. No new decision tickets.
---
<!-- COMMENTS:END -->
