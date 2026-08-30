---
id: TASK-130
title: >-
  ATS topology: build TenantIdentity + "context-gathering opportunity" finding
  category
status: Done
assignee:
  - '@claude'
created_date: '2026-08-29 20:45'
updated_date: '2026-08-30 13:45'
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
- [x] #1 TenantIdentity model + migration (provider, tenant identifier, created_at; no credential fields); Scenario belongs_to :tenant_identity (optional); a spec asserts lookup-or-create by (provider, tenant identifier)
- [x] #2 HandshakeCheck / comparison output emits a 'context-gathering opportunity' result for optional-and-missing signatures and un-mapped observed fields, ranked; a spec covers at least one opportunity and the empty case
- [x] #3 The guided-session review page renders the ranked opportunities alongside drift findings, read-only
- [x] #4 No opportunity is auto-acted on; brakeman + rubocop -a clean
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented ADR 010 §4 — the Signature Registry as ATS topology.

**TenantIdentity** (`tenant_identities`: `provider` + `identifier`, unique together; timestamps; no credential fields)
- `TenantIdentity.for(provider:, identifier:)` — find-or-create; nil identifier → nil.
- `Scenario belongs_to :tenant_identity, optional: true`.
- `Scenarios::TenantIdentifier.call(provider, source_url)` — derives the employer identifier from what's already in the URL: board slug for greenhouse/lever/ashby/breezy, tenant subdomain for `*.myworkdayjobs.com`, bare host otherwise. Pure function.
- `Scenarios::GuidedCapture` attributes every materialized `Scenario` to its `TenantIdentity`.

**Context-gathering opportunities** — `Scenarios::ContextOpportunities.call(scenario, purpose:)` returns a ranked `Opportunity(kind, reason, rank)` list. Decision: a **computed list, not a persisted `ComparisonFinding` category** — opportunities are advisory, recomputable, and carry no disposition workflow, unlike the immutable drift/coverage findings. v1 flags `optional-and-missing` signatures from `HandshakeCheck`. Rendered read-only in an "Opportunities to gather more context" section on the guided-session review page (`_reference_comparison.html.erb`), below drift findings.

**Descoped → TASK-132**: "un-mapped observed fields" as opportunities. That needs the `ApplicationFieldMapping` join, which is `UserJobPosting`-scoped, not on the `Scenario`; the service currently takes only a `Scenario`. Noted in the service and in `signature-registry.md`.

**Docs**: `signature-registry.md` "Decided" updated (TenantIdentity built; ContextOpportunities shape + the computed-not-persisted rationale + the follow-up).

**Tests**: `spec/models/tenant_identity_spec.rb`, `spec/services/scenarios/tenant_identifier_spec.rb`, `spec/services/scenarios/context_opportunities_spec.rb` (all new), plus additions to `guided_capture_spec.rb` (tenant attribution) and `guided_sessions_spec.rb` (review-page render). Broad sweep (`spec/services/scenarios` + `spec/models` + guided/api/companies/job_postings requests + helpers) = 449 examples, 0 failures. rubocop + erb_lint + brakeman clean. No extension change.
<!-- SECTION:FINAL_SUMMARY:END -->
