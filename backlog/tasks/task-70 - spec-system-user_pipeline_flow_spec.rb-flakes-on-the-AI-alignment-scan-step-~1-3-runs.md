---
id: TASK-70
title: >-
  spec/system/user_pipeline_flow_spec.rb flakes on the AI alignment-scan step
  (~1/3 runs)
status: To Do
assignee: []
created_date: '2026-08-19 15:00'
labels: []
dependencies: []
references:
  - spec/system/user_pipeline_flow_spec.rb
priority: low
type: bug
ordinal: 83000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Found while verifying TASK-69 didn't regress anything: `spec/system/user_pipeline_flow_spec.rb:16` ("allows a user to favorite a job and run an alignment scan") fails intermittently even on a clean checkout with none of TASK-69's changes applied -- reproduced via `git stash` + rerun, 1 failure in 3 clean runs.

This is NOT the same bug as TASK-56 (queue_adapter test pollution, closed 2026-08-19) -- different spec, different symptom. Failure is `expect(page).to have_text(/AI alignment scan complete/i)` timing out; the page instead shows "No match analysis yet" -- i.e. clicking "Check Match" never completes the alignment-scan flow within Capybara's wait window. The webmock stub for `http://localhost:11500/v1/chat/completions` is in place in the spec, so this looks like a Cuprite/Capybara timing race on the async job + Turbo Stream broadcast that renders the result, not a real LLM connectivity issue (those show up as distinct `[Orchestrator] Model execution failed` log lines elsewhere and aren't specific to this spec).

Reproduce: `bundle exec rspec spec/system/user_pipeline_flow_spec.rb:16` a few times in a row: passed 2/3, failed 1/3, and hung past a 90s timeout on one attempt (this one is the more concerning data point -- a real hang, not just a slow assertion).
<!-- SECTION:DESCRIPTION:END -->
