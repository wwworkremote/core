---
id: doc-3
title: 'Test Suite Audit Findings (May 22, 2026)'
type: other
created_date: '2026-05-23 12:57'
---
# Test Suite Audit Findings: May 22, 2026

## Overview
Smoke tests are passing consistently, but the application test suite is flagging five specific regressions. These are isolated from infrastructure stability and point to business logic and data drift.

## Identified Failures

### 1. Contract Drift: YC Scraper
- **Spec:** `spec/contracts/yc_spec.rb`
- **Error:** HTTP 406 (Not Acceptable) and missing `data-page` attribute.
- **Root Cause:** External YC API response schema or request headers have drifted.

### 2. Performance Regression: Admin::Sources
- **Spec:** `spec/requests/admin/sources_spec.rb`
- **Error:** `Bullet::Notification::UnoptimizedQueryError`
- **Root Cause:** N+1 query issue in `Admin::Sources` when accessing `job_boards_documents`.

### 3. Logic Drift: Charts::Data::Sources
- **Spec:** `spec/requests/charts/data/sources_spec.rb`
- **Error:** Expected registration velocity of 1, got 3.
- **Root Cause:** Test data pollution; multiple sources are being created in the test suite that are now being included in the velocity count.

## Action Plan
- **TASK-11:** Fix YC Scraper contract.
- **TASK-12:** Implement counter cache for `JobBoards::Source` to resolve N+1.
- **TASK-13:** Isolate test data for velocity metrics.
