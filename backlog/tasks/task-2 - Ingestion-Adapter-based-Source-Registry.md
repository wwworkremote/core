---
id: TASK-2
title: 'Ingestion: Adapter-based Source Registry'
status: Done
assignee: []
created_date: '2026-05-06 03:03'
updated_date: '2026-05-06 03:20'
labels:
  - architecture
  - ingestion
  - shared-dependency
dependencies: []
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Refactor DataAcquisitionManager to use a registry of Source Adapters. Each adapter owns its cooldown, URL building, and invocation logic. Eliminates pass-through complexity in the manager.
<!-- SECTION:DESCRIPTION:END -->
