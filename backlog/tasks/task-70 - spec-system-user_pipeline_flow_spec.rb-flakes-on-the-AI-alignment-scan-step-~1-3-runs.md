---
id: TASK-70
title: Multiple system specs flake on LLM/Turbo-Stream timing races (~1/3 runs)
status: To Do
assignee: []
created_date: '2026-08-19 15:00'
updated_date: '2026-08-19 18:18'
labels: []
dependencies: []
references:
  - spec/system/user_pipeline_flow_spec.rb
priority: medium
type: bug
ordinal: 83000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Found while verifying TASK-69 didn't regress anything: `spec/system/user_pipeline_flow_spec.rb:16` ("allows a user to favorite a job and run an alignment scan") fails intermittently even on a clean checkout with none of TASK-69's changes applied -- reproduced via `git stash` + rerun, 1 failure in 3 clean runs.

Second occurrence, found while verifying TASK-68 (jobs.rubyonrails.org ingestion, unrelated files): `spec/system/llm_chat_flow_spec.rb:21` failed once in a full-suite run, passed cleanly on immediate isolated rerun.

Third occurrence, found when TASK-68's own commit got blocked by the pre-commit hook's RSpec run: `spec/system/job_ingestion_flow_spec.rb:85` ("executes the full ingestion sequence from UI trigger to Enriched JobPosting") failed in the hook's full-suite run (872 examples via the combined spec/ + packages/ingestion/spec/ run overcommit uses), passed cleanly on immediate isolated rerun. This is now blocking real commits, not just showing up in ad-hoc verification runs -- bumped to Medium priority.

Three independent specs, three unrelated changes, identical shape: passes in isolation every time, fails only under full-suite load. This is not the same bug as TASK-56 (queue_adapter test pollution, closed 2026-08-19) -- different symptom (a stalled/timed-out UI wait racing an async job + Turbo Stream broadcast, not a wrong-adapter job-enqueue assertion). Strongly smells like one shared root cause: Cuprite/Capybara's wait window vs. SolidQueue/Turbo Stream broadcast latency degrading under full-suite parallel/sequential load.

Reproduce: run the full suite (`bundle exec rspec spec packages/ingestion/spec`) repeatedly -- expect roughly 1 in 3 runs to fail one of these three specs (or possibly another system spec sharing the same shape not yet observed). Isolated single-file reruns of the failing spec pass every time observed so far.
<!-- SECTION:DESCRIPTION:END -->
