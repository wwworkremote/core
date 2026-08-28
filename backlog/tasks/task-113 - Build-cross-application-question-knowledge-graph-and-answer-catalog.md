---
id: TASK-113
title: Build cross-application question knowledge graph and answer catalog
status: To Do
assignee: []
created_date: '2026-08-28 22:51'
updated_date: '2026-08-28 22:52'
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
<!-- COMMENTS:END -->
