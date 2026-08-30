---
id: TASK-132
title: 'Context opportunities: flag un-mapped observed application fields'
status: To Do
assignee: []
created_date: '2026-08-30 13:45'
labels:
  - application-capture-datalake
  - 'wayfinder-map:doc-7'
dependencies:
  - TASK-130
references:
  - app/services/scenarios/context_opportunities.rb
  - docs/adr/010-link-to-application-capture-and-the-datalake.md
priority: low
type: enhancement
ordinal: 148000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Follow-up to TASK-130. ADR 010 §4 lists two opportunity sources: `optional-and-missing` signatures (done in TASK-130) and **un-mapped observed fields**. The second was deferred because the mapping data (`ApplicationFieldMapping`) is `UserJobPosting`-scoped, not on the `Scenario`, and `Scenarios::ContextOpportunities` currently takes only a `Scenario`.

## Scope

- When the guided session has a `user_job_posting`, join its `application_field_observations` against its `application_field_mappings` and emit an opportunity for each observed field with no semantic mapping ("this employer asks X and we have no strategy for it").
- Feed it into `Scenarios::ContextOpportunities` (pass the guided session or its UJP, not just the scenario) and rank alongside the signature opportunities.
- Extend the review-page section + spec.

## Out of scope

- Persisting opportunities or giving them a disposition workflow — they stay a computed advisory list.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Scenarios::ContextOpportunities emits an opportunity for each ApplicationFieldObservation on the session's UserJobPosting that has no corresponding ApplicationFieldMapping; a spec covers the mapped vs un-mapped split
- [ ] #2 The opportunities are ranked together with the signature opportunities and rendered on the guided-session review page
- [ ] #3 Sessions with no user_job_posting still work (signature opportunities only); rubocop + brakeman clean
<!-- AC:END -->
