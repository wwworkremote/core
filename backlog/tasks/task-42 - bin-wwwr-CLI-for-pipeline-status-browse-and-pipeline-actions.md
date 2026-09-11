---
id: TASK-42
title: 'bin/wwwr CLI for pipeline status, browse, and pipeline actions'
status: Done
assignee: []
created_date: '2026-08-14 17:31'
updated_date: '2026-08-14 20:01'
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

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Built bin/wwwr as a 5-line Ruby shim (no Thor -- not in the Gemfile, unneeded for a personal CLI) around lib/wwwr/cli.rb: `status` for a one-screen health summary (postings/sources/pending-documents counts, pause state, queue error rate, reusing the same metrics admin/dashboard and admin/observability already compute), `postings [filters]` reusing JobPosting's own scopes directly (contract_only, remote_only, location_matches, by_role_family) with the same default ignored/purged/expired exclusion as JobPostingsController#base_job_postings, and `transition <id> <event>` reusing Admin::PipelineStepsController::STATUS_EVENTS verbatim so valid events can't drift from the web UI. 6 new specs (lib/wwwr split out specifically so it's requireable/testable without shelling out), full suite green, landed as 613764d. Verified live against dev data (bin/wwwr status, bin/wwwr postings --contract, bin/wwwr transition against a bad id).
<!-- SECTION:FINAL_SUMMARY:END -->
