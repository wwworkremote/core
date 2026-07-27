---
id: TASK-14
title: Fix bin/ci hardcoded Colima socket path
status: To Do
assignee: []
created_date: '2026-07-27 17:27'
labels: []
dependencies: []
references:
  - bin/ci
priority: medium
ordinal: 14000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
bin/ci guesses the Colima docker socket at ~/.config/colima/default/docker.sock. Per platform decision Z-195/Z-181 (2026-07-04), ~/.colima is now canonical and colima ignores XDG paths -- the hardcoded fallback silently misses the real socket. Should shell out to colima-status socket instead.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 bin/ci uses 'colima-status socket' (or 'colima-status --json .socket') as the source of truth instead of guessing paths
- [ ] #2 bin/ci still works when DOCKER_HOST is already set (current docker context check preserved)
<!-- AC:END -->
