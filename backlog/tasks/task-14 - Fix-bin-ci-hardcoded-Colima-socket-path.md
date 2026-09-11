---
id: TASK-14
title: Fix bin/ci hardcoded Colima socket path
status: Done
assignee: []
created_date: '2026-07-27 17:27'
updated_date: '2026-08-27 17:59'
labels: []
dependencies: []
references:
  - bin/ci
modified_files:
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
- [x] #1 bin/ci uses 'colima-status socket' (or 'colima-status --json .socket') as the source of truth instead of guessing paths
- [x] #2 bin/ci still works when DOCKER_HOST is already set (current docker context check preserved)
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Fallback path now shells out to colima-status socket (confirmed working on this machine: resolves /Users/mike/.colima/default/docker.sock) instead of guessing ~/.config/colima/default/docker.sock, which colima ignores per Z-195/Z-181. The existing docker-context-inspect check (AC #2) is untouched -- it already resolves correctly on this machine and remains the first attempt before the colima-status fallback. Shellcheck clean (one pre-existing, unrelated warning on a line not touched).
<!-- SECTION:FINAL_SUMMARY:END -->
