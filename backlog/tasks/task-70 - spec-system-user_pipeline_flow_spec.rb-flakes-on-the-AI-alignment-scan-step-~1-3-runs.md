---
id: TASK-70
title: Multiple system specs flake on LLM/Turbo-Stream timing races (~1/3 runs)
status: To Do
assignee: []
created_date: '2026-08-19 15:00'
updated_date: '2026-08-19 20:15'
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

**Fourth occurrence broadens the theory**: a brand-new plain request spec (`spec/requests/navigation_spec.rb`, no Capybara/Cuprite involved at all) failed in the pre-commit hook's 878-example combined run -- 3 examples, all asserting on the homepage response body (`not_to include("translation missing")`, `aria-current` presence). Passed cleanly both in isolation (246 examples, just this file + packages/ingestion/spec) and in a full 878-example run with `--seed 1`. This means the pollution isn't Cuprite/Turbo-Stream-specific after all -- it's broader shared state affecting plain request-spec rendering too, most likely leftover DB rows or Rails.cache state leaking from an earlier example into `home/index.html.erb`'s render (that view has 33 separate `t()` calls, some likely behind conditional data that could differ depending on what a prior spec left in the DB).

Three independent specs, three unrelated changes, identical shape: passes in isolation every time, fails only under full-suite load, at a moderate/inconsistent rate (not every seed). This is not the same bug as TASK-56 (queue_adapter test pollution, closed 2026-08-19) -- different symptom. No longer confidently attributable to Cuprite/Capybara timing alone given the 4th occurrence; leaked DB state or Rails.cache pollution is now the leading theory.

Reproduce: run the full suite (`bundle exec rspec spec packages/ingestion/spec`) repeatedly with different seeds -- expect an occasional failure in one of these specs (or another sharing the same shape). Isolated single-file reruns of any failing spec have passed every time observed so far.
<!-- SECTION:DESCRIPTION:END -->
