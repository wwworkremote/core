---
id: TASK-144.1
title: 'Interview Prep Pack: add a posting-anchored Domain Primer section'
status: In Progress
assignee: []
created_date: '2026-09-02 18:56'
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
- [ ] #1 The generated pack contains a DOMAIN PRIMER section positioned after THE SETUP and before YOUR STORY
- [ ] #2 Primer content is driven by the specific posting (its responsibilities, stack, team, and the business served), not a generic domain dump
- [ ] #3 Primer splits concepts into 'MUST know for this interview' vs 'useful context'
- [ ] #4 Primer includes a blind-spots subsection derived from the candidate's actual background
- [ ] #5 Primer includes named learning resources with a 'verify links' caveat
- [ ] #6 prompt_builder_spec asserts the DOMAIN PRIMER instruction, the blind-spots instruction, and the verify-links caveat are present
- [ ] #7 docs/research/interview-prep-basis-dsp.md carries a hand-written domain primer (Part 1) and the new row in the Part 2 spec table; CONTEXT.md and docs/changelog.md updated
- [ ] #8 The Basis pack (UJP #268) is regenerated so it carries the new section
<!-- AC:END -->
