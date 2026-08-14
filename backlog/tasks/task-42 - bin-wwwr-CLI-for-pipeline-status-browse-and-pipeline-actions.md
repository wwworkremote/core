---
id: TASK-42
title: 'bin/wwwr CLI for pipeline status, browse, and pipeline actions'
status: In Progress
assignee: []
created_date: '2026-08-14 17:31'
updated_date: '2026-08-14 19:58'
labels:
  - cli
  - ux
dependencies: []
priority: medium
type: feature
ordinal: 48000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Mike wants more ways to open and interact with the system beyond the browser. Lightest-weight first step: a local `bin/wwwr` CLI (Thor or plain OptionParser -- Rails runner context, no new dependency needed) that talks to the existing models/DB directly, covering read-mostly commands first: pipeline/ingestion status summary, listing/searching job postings with the same filters the web UI has (company, location, remote, role_family, and the new contract filter from task-40), and marking a posting's pipeline status (interested/ignore/applied). This becomes the shared foundation for both Raycast/Shortcuts (which can shell out to a local executable directly, no API needed) and the SwiftBar menu-bar plugin (task-43).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 bin/wwwr status prints a one-screen pipeline/ingestion health summary
- [ ] #2 bin/wwwr postings [filters] lists job postings with the same filter vocabulary as job_postings#index
- [ ] #3 bin/wwwr can transition a posting's pipeline status by id
- [ ] #4 Runs via `bin/wwwr` with no separate server process required
<!-- AC:END -->
