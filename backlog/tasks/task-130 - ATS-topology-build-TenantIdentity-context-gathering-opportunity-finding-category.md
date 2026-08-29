---
id: TASK-130
title: >-
  ATS topology: build TenantIdentity + "context-gathering opportunity" finding
  category
status: To Do
assignee: []
created_date: '2026-08-29 20:45'
labels:
  - application-capture-datalake
  - 'wayfinder-map:doc-7'
dependencies: []
references:
  - docs/adr/010-link-to-application-capture-and-the-datalake.md
  - docs/architecture/signature-registry.md
priority: low
type: feature
ordinal: 146000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implements ADR 010 §4. Makes "map the topology of a system I can't change, and identify opportunities to gather more context" concrete by extending the Signature Registry — no new subsystem.

## Scope

- `TenantIdentity` model + migration: `provider`, tenant/employer identifier, `created_at`. Never credentials — only "an account/tenant exists here". `Scenario belongs_to :tenant_identity, optional: true` (shape already sketched in signature-registry.md "Decided"). A new capture at the same employer looks this up before assuming sense-making from zero.
- New finding category "context-gathering opportunity" on `Scenarios::HandshakeCheck` / comparison output: `optional-and-missing` signatures and observed-but-un-mapped fields become ranked, reviewable "could capture this" items. Additive to the existing `ComparisonFinding` category vocabulary (drift / coverage_gap) — decide whether it is a third `category` value or a distinct list; ADR 010 leaves that to implementation.
- Surface the ranked opportunities on the guided-session review page (where drift findings already render).

## Out of scope

- Closed-shadow-DOM capture (map "Out of scope").
- The datalake raw-asset side (TASK-126) — this task is about the structured registry, which is fed from value-free evidence today and can be enriched from `Datalake::Bundle` later.
- Auto-acting on an opportunity — it is a reviewable suggestion only.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 TenantIdentity model + migration (provider, tenant identifier, created_at; no credential fields); Scenario belongs_to :tenant_identity (optional); a spec asserts lookup-or-create by (provider, tenant identifier)
- [ ] #2 HandshakeCheck / comparison output emits a 'context-gathering opportunity' result for optional-and-missing signatures and un-mapped observed fields, ranked; a spec covers at least one opportunity and the empty case
- [ ] #3 The guided-session review page renders the ranked opportunities alongside drift findings, read-only
- [ ] #4 No opportunity is auto-acted on; brakeman + rubocop -a clean
<!-- AC:END -->
