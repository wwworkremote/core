---
id: TASK-103
title: Build TenantIdentity (per-employer identity reused across applications)
status: To Do
assignee: []
created_date: '2026-08-27 17:24'
labels:
  - architecture
  - signature-registry
dependencies: []
documentation:
  - docs/architecture/signature-registry.md
priority: medium
type: feature
ordinal: 300
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Decided 2026-08-27 (docs/architecture/signature-registry.md, "Decided" section): a tenant-level identity (e.g. a Workday account created mid-application) gets its own record, referenced by Scenario -- not just another ScenarioSignature. Without this, every application at the same employer re-discovers "do I already have an account here" from zero instead of recognizing it.

Likely shape (from the doc, not yet finalized in code): TenantIdentity -- provider, an employer/tenant identifier, created_at. Never credentials -- just "an account exists here." Scenario gets an optional belongs_to :tenant_identity.

Independent of the other tasks in this plan -- no dependency, can be built any time.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 TenantIdentity model + migration exists matching the shape in signature-registry.md's 'Decided' section (or an explicitly documented deviation)
- [ ] #2 Scenario has an optional belongs_to :tenant_identity
- [ ] #3 No credentials or secrets are ever stored on this model -- identity existence only
- [ ] #4 Model spec covering the association and the 'lookup before assuming a new identity is needed' use case
<!-- AC:END -->
