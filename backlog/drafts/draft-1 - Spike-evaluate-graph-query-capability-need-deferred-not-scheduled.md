---
id: DRAFT-1
title: 'Spike: evaluate graph-query capability need (deferred, not scheduled)'
status: Draft
assignee: []
created_date: '2026-08-08 15:50'
labels: []
milestone: m-0
dependencies: []
parent_task_id: TASK-32
type: spike
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Deferred/parking-lot item from the 2026-08-08 capability audit. NOT scheduled for execution under this milestone -- kept as a Draft so the question isn't lost, not as committed work.

The question raised: does this codebase need graph-query capability (e.g. Postgres property-graph/SQL-PGQ support, or a dedicated graph extension/database)? The domain is graph-shaped (Company <-> JobPosting <-> User <-> Contact <-> Domain relationships), but:
- Today these relationships are plain ActiveRecord FK joins, which are adequate at current scale -- no concrete traversal query exists today that FK joins can't express reasonably.
- The claim that an upcoming Postgres version ships native graph-query support was raised in conversation but is NOT independently verified -- do not treat it as confirmed; check current official Postgres release notes/roadmap before relying on it.

This should only be promoted out of Draft if a concrete, currently-unmet traversal query need appears (e.g. multi-hop "companies that later hired people who worked at X" style queries that plain joins make awkward). Promoting it without that concrete driver would be solving a problem the codebase doesn't have yet.
<!-- SECTION:DESCRIPTION:END -->
