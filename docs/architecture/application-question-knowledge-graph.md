# Application Question Knowledge Graph

## Purpose

Application research should accumulate more than a list of fields. Each
observed question is evidence about an application, while repeated evidence
reveals question archetypes, reusable answer strategies, provider conventions,
and differences among companies and industries. The graph must preserve both:
the exact occurrence and the learned pattern.

The existing model has three useful but disconnected seams:

- `ApplicationFieldObservation` is the per-application observation, including
  normalized prompt, question kind, page step, persona, and trace.
- `ApplicationQuestion` stores a question and answer associated with a posting.
- `ApplicationAnswerTemplate` stores reusable answers by normalized prompt and
  persona.

TASK-113 connects those seams without redefining any one of them as the whole
truth.

## Concept graph

```mermaid
flowchart LR
    OCC["Question Occurrence<br/>exact wording + context"]
    ARC["Question Archetype<br/>reviewable semantic cluster"]
    STR["Answer Strategy<br/>source + persona + version"]
    APP["Application / Guided Session"]
    JOB["Job Posting"]
    COM["Company"]
    IND["Industry"]
    PRO["Provider"]
    PER["Resume Persona"]
    OUT["Application Outcome"]

    APP --> OCC
    OCC --> JOB --> COM --> IND
    OCC --> PRO
    OCC --> PER
    APP --> OUT
    OCC -->|"reviewed membership"| ARC
    ARC --> STR
    STR --> PER
    OUT -."evidence, not causation".-> STR
```

The graph edge from outcome to answer strategy is deliberately evidentiary.
An interview or rejection can correlate with an answer, but this system must
not claim the answer caused the outcome without stronger evidence.

## Occurrence-to-answer loop

```mermaid
flowchart TD
    O["Observe exact question"] --> N["Normalize wording<br/>without discarding original"]
    N --> M{"Known archetype?"}
    M -->|"high-confidence candidate"| R["Human-reviewable membership"]
    M -->|"unknown or ambiguous"| P["Propose new archetype or split"]
    P --> R
    R --> C["Count across applications,<br/>companies, industries, providers"]
    C --> S{"Answer sophistication"}
    S -->|"deterministic fact"| D["Profile-derived answer"]
    S -->|"stable authored response"| T["Persona-aware template"]
    S -->|"contextual judgment"| A["Evidence-backed synthesis + review"]
    D --> V["Versioned answer candidate"]
    T --> V
    A --> V
    V --> H["Mike reviews, edits, copies, or declines"]
    H --> E["Record actual use and later outcome"]
    E --> C
```

## Invariants

1. An occurrence is never overwritten by an archetype assignment.
2. Raw wording and normalized wording coexist.
3. Archetype membership has provenance and confidence and can be corrected.
4. Answer strategies are versioned and persona-aware.
5. “Most common” and “best answer” are separate questions.
6. Submitted answers outrank proposed answers as evidence of what happened, but
   do not silently become universal templates.
7. Outcomes enrich analysis but do not establish causal claims by themselves.
8. Recommendations never cross the commitment boundary or submit applications.

## Views this enables

- Most common archetypes overall and by company, industry, provider, or role.
- Wording variants inside one archetype.
- Deterministic versus authored versus sophisticated-answer demand.
- Coverage: archetypes with no approved answer strategy.
- Persona fit: where the same archetype needs meaningfully different answers.
- Drift: new archetypes or wording variants appearing in a provider flow.
- Outcome overlays with explicit sample sizes and non-causal language.

## Automation readiness

*(wayfinder map doc-7 / [ADR 010](../adr/010-link-to-application-capture-and-the-datalake.md);
full contract on
[Automation-readiness corpus and eval-harness shape](../../backlog/tasks/task-124%20-%20Wayfinder-decision-automation-readiness-corpus-and-eval-harness-shape.md);
implementation TASK-127.)*

The **Question Archetype is the unit of automation readiness.** "Adapt the system toward
automating these applications" means building a decision corpus and an eval loop — not a
training run.

- **`archetype_readiness_assessments`** — append-only, FindingDisposition-style. One
  archetype's readiness class is `deterministic` / `generatable` / `needs-human`, assigned
  by Mike during archetype review with an evidence-based **suggested default** (inputs:
  occurrence frequency, historically-winning strategy source, median edit distance,
  sample-size floor). Latest applicable assessment wins for presentation; a merge or split
  carries the prior assessment forward as a *suggestion*, never silently.
- **`answer_proposal_verdicts`** — **value-free**. sha256 hashes + `edit_distance` +
  `strategy_source` (`canned` / `template` / `ai`) + `verdict`
  (`accepted` / `edited` / `declined`). One row per proposal shown in the sidepanel
  answer flow (TASK-78), declines included. No answer text.
- **The eval harness replays the real path** — `LLM::AnswerGenerator.call` (`CannedAnswers`
  + `ApplicationAnswerTemplate` + `PromptBuilder` / prompt constants + the configured
  `answer_generation` model) — and reports verbatim-acceptance rate + median edit distance,
  split by strategy. Corpus is per-archetype JSONL under `data/datalake/corpus/`
  (git-ignored). `rake automation_readiness:corpus` + `automation_readiness:eval`.
- **Advisory only, hard guardrail** (invariant 8 extended): nothing the readiness loop
  produces flips an archetype to auto-fill or auto-submit. It only ever changes whether a
  proposal is offered *without* a review prompt — never whether an answer is entered or
  sent.

## Delivery boundary

The first implementation should use the relational database as the source of
truth and project a graph-shaped read model for visualization. A dedicated
graph database is not justified until real traversal or scale evidence shows
the relational joins and aggregates are insufficient.
