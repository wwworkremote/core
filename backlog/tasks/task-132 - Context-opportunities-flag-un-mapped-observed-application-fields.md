---
id: TASK-132
title: 'Context opportunities: flag un-mapped observed application fields'
status: Done
assignee:
  - '@claude'
created_date: '2026-08-30 13:45'
updated_date: '2026-08-30 13:51'
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
- [x] #1 Scenarios::ContextOpportunities emits an opportunity for each ApplicationFieldObservation on the session's UserJobPosting that has no corresponding ApplicationFieldMapping; a spec covers the mapped vs un-mapped split
- [x] #2 The opportunities are ranked together with the signature opportunities and rendered on the guided-session review page
- [x] #3 Sessions with no user_job_posting still work (signature opportunities only); rubocop + brakeman clean
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
`Scenarios::ContextOpportunities.call` now takes an optional `user_job_posting:` kwarg. When present, it emits a `field:<key>` opportunity for every `ApplicationFieldObservation` on that application whose `field_key` has no `ApplicationFieldMapping` ("this employer asks X and we have no answer strategy"). Ranked together with the signature opportunities. The review-page partial passes `guided_session.user_job_posting`; sessions without one keep working (signature opportunities only).

New: `spec/factories/application_field_observations.rb`. Spec added for the mapped-vs-unmapped split. `signature-registry.md` note updated (follow-up folded in). rubocop + brakeman clean. No extension change.
<!-- SECTION:FINAL_SUMMARY:END -->
