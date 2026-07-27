---
id: TASK-17
title: Document that bin/dev has no Colima/Docker dependency
status: To Do
assignee: []
created_date: '2026-07-27 17:27'
labels: []
dependencies: []
references:
  - docs/development.md
  - docker-compose.yml
priority: low
ordinal: 17000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
docker-compose.yml exists for optional containerized builds and bin/ci (act), but the actual dev loop (bin/dev via Procfile.dev) runs Puma/SolidQueue/Tailwind directly against host Postgres with zero Colima involvement. This isn't documented anywhere, so it reads as a heavier dependency than it is. Clarify scope in docs/development.md so nobody assumes Colima is required to run the app.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 docs/development.md Prerequisites section marks Docker/Colima explicitly optional (act CI + container builds only)
- [ ] #2 docker-compose.yml gets a top comment clarifying it is not used by bin/dev
<!-- AC:END -->
