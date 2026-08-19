---
id: TASK-70
title: Multiple system specs flake on LLM/Turbo-Stream timing races (~1/3 runs)
status: To Do
assignee: []
created_date: '2026-08-19 15:00'
updated_date: '2026-08-19 18:13'
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

Second occurrence found while verifying TASK-68 (jobs.rubyonrails.org ingestion, unrelated files): `spec/system/llm_chat_flow_spec.rb:21` ("allows a user to start a dialogue and receive a simulated response") failed once in a full-suite run, passed cleanly on immediate isolated rerun -- same signature (an async job + Turbo Stream broadcast racing Capybara's wait window), different spec file. Two independent specs, two unrelated feature branches touching totally different files, same failure shape -- this smells like one shared root cause (Cuprite/Capybara timing vs. SolidQueue/Turbo Stream broadcast latency under load), not two unrelated flakes.

This is NOT the same bug as TASK-56 (queue_adapter test pollution, closed 2026-08-19) -- different symptom (a stalled/timed-out UI wait, not a wrong-adapter job-enqueue assertion).

Reproduce: `bundle exec rspec spec/system/user_pipeline_flow_spec.rb:16` a few times in a row: passed 2/3, failed 1/3, and hung past a 90s timeout on one attempt (this one is the more concerning data point -- a real hang, not just a slow assertion).
<!-- SECTION:DESCRIPTION:END -->
