---
id: TASK-144.1
title: 'Interview Prep Pack: add a posting-anchored Domain Primer section'
status: Done
assignee: []
created_date: '2026-09-02 18:56'
updated_date: '2026-09-02 19:02'
labels:
  - job-search
  - llm
dependencies: []
parent_task_id: TASK-144
priority: high
type: enhancement
ordinal: 162000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Mike wants the prep pack to teach him the industry domain the role serves — the fundamental concepts, key terms, business model, best practices, and the "things I haven't even thought of" — scoped tightly to what THIS posting actually requires, with links to further learning. Top priority signal is the job posting's own stated needs and requirements.

Prompt-only change to LLM::InterviewPrepGenerator::PromptBuilder: a new "DOMAIN PRIMER" section (placed second, right after THE SETUP, before YOUR STORY) instructing the model to produce, all driven by the JOB_POSTING and ordered by how strongly the posting signals each item:
- what the business does / how it makes money / where the role sits in that flow
- concepts + vocabulary the seat assumes, split "MUST know for this interview" vs "useful context", one plain line each
- domain best practices an interviewer expects the candidate to reach for
- blind spots: what the domain takes for granted that someone with THIS candidate's background (from History) would not know to ask about, and why each matters
- learning resources: canonical sources named; URL only when certain, else name it; prefixed "Verify links before relying on them"

No live web research in v1 — the primer is the model's own knowledge, anchored by the posting. A future research step could ground the links (noted in the reference doc).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The generated pack contains a DOMAIN PRIMER section positioned after THE SETUP and before YOUR STORY
- [x] #2 Primer content is driven by the specific posting (its responsibilities, stack, team, and the business served), not a generic domain dump
- [x] #3 Primer splits concepts into 'MUST know for this interview' vs 'useful context'
- [x] #4 Primer includes a blind-spots subsection derived from the candidate's actual background
- [x] #5 Primer includes named learning resources with a 'verify links' caveat
- [x] #6 prompt_builder_spec asserts the DOMAIN PRIMER instruction, the blind-spots instruction, and the verify-links caveat are present
- [x] #7 docs/interview-prep/_reference/reference.md carries a hand-written domain primer (Part 1) and the new row in the Part 2 spec table; CONTEXT.md and docs/changelog.md updated
- [x] #8 The Basis pack (UJP #268) is regenerated so it carries the new section
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Regenerated the Basis pack (UJP #268): 10,693 chars, DOMAIN PRIMER now section 2, renders on https://wwworkremote.localhost/job_postings/7068. Structure correct on the local 7B (MUST KNOW vs USEFUL CONTEXT split, blind spots, learning resources w/ verify caveat).

Quality caveat (local 7B): the primer is shallow and the model misreads two things -- (1) it fills USEFUL CONTEXT with the candidate's own stack (OTel/Kafka/React) instead of domain concepts; (2) blind spots conflates skill gaps (Java/React, which belong in THE SETUP) with real domain blind spots. Learning-resource URLs are partly hallucinated (Adobe whitepaper, arxiv link). The IAB OpenRTB spec -- the single most important resource -- is missing. The hand-written primer in docs/interview-prep/_reference/reference.md is the good version. Two prompt guardrails would help any model (USEFUL CONTEXT = domain not candidate-stack; blind spots != skill gaps; a fabricated URL is worse than a named source) but the real fix is a capable model on this path -> TASK-145.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added a DOMAIN PRIMER section (section 2, after THE SETUP, before YOUR STORY) to the interview prep pack. Prompt-only change to `LLM::InterviewPrepGenerator::PromptBuilder#default_prompt`: instructs the model to produce posting-anchored industry knowledge — business model + where the role sits, must-know vs useful-context vocabulary, domain best practices, blind spots computed against the candidate's own History, and named learning resources flagged "verify links". Sections renumbered 7 → 8.

`prompt_builder_spec` asserts the primer / blind-spots / verify-links instructions are present (13 examples green; full sweep 104 green). `docs/interview-prep/_reference/reference.md` gains a hand-written programmatic-advertising / DSP primer in Part 1 (RTB, OpenRTB, first-price auctions + bid shading, budget pacing as a control problem, the Platform↔DSP seam, cookie-deprecation, ad fraud, thin-margin P&L) and a new row in the Part 2 spec table; CONTEXT.md + docs/changelog.md updated. Basis pack (UJP #268) regenerated.

Known limitation: on the local 7B the primer comes out shallow and slightly confused (mixes the candidate's tech stack into "useful context", conflates skill gaps with domain blind spots, hallucinates two resource URLs). The hand-written primer in the reference doc is the quality bar; getting there in the generated pack needs a capable model on the orchestrator path (blocked on TASK-145). Optional follow-up: two prompt guardrails (useful-context = domain not candidate-stack; blind-spots ≠ skill-gaps; prefer a named source to a guessed URL).

Commit ec3f6c20 on branch feat/interview-prep-pack.
<!-- SECTION:FINAL_SUMMARY:END -->
