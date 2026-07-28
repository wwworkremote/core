---
id: doc-1
title: Smoke Test Deployment and Mandates
type: specification
created_date: '2026-05-23 05:09'
tags:
  - smoke-test
  - infrastructure
  - architecture
---
# Smoke Test Suite Deployment & Operational Mandates

## Summary
Successfully implemented `bin/smoke` and `bin/verify_ingestion` to provide CI-ready end-to-end verification.

## Architectural Mandates
- **Asymmetric Sync Rule:** Mandates Soft Deletes to prevent data resurrection.
- **zdots Rule:** Mandates database account separation (`_ro`, `_w`, `_rw`) to prevent drift.
- **Solid Stack Safety:** Mandates explicit `connects_to` writes for SolidQueue/Cache/Cable.

## Known Test Instabilities (To be addressed in TASK-8)
The following tests are currently failing due to environmental/infrastructure issues (circuit breakers, missing GeoIP database, service connection issues):
- `YC Scraper Contract`
- `Charts::Data::Sources`
- `Admin::Sources`

These are logged and prioritized for the Post-Cleanup Dead File Review (TASK-8).
