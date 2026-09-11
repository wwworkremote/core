---
id: TASK-55
title: Close the 14 zero-coverage files (test suite audit)
status: Done
assignee: []
created_date: '2026-08-16 15:22'
updated_date: '2026-08-16 16:59'
labels: []
dependencies: []
priority: medium
type: chore
ordinal: 61000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
CORRECTED 2026-08-16: the 78% figure originally cited here was wrong -- it came from a bare `bundle exec rspec` run, which only covers root spec/ and silently excludes packages/ingestion/spec (RSpec's default_path is "spec", and the ingestion engine's specs live outside it -- see the comment on the RSpec entry in .overcommit.yml, which already knows this and runs `bundle exec rspec spec packages/ingestion/spec` explicitly). Running the actual pre-commit-equivalent command gives the true baseline: 717 examples, 0 failures, 91.19% line coverage (6029/6611). The 91.15% figure originally dismissed as "SimpaCov merge noise" was in fact close to correct.

The 14 zero-coverage files below are unaffected by this correction (verified against the accurate combined run) -- all are root app/ files, not part of the ingestion package, so they were genuinely zero either way: admin/extraction_rules_controller.rb, pages_controller.rb, api/v0/sources_controller.rb, models_controller.rb, admin/documents_controller.rb, admin/interview_questions_controller.rb, admin/pipeline_filters_controller.rb, job_lifecycle/expiry_sweep_job.rb, admin/interview_sessions_controller.rb, api/v0/geo_controller.rb, solid_queue_maintenance/stale_job_pruner.rb, admin/pipeline_prompts_controller.rb, job_boards/strategy_agent.rb, admin/skills_controller.rb.

Explicitly NOT chasing literal 100% -- some of this is thin admin CRUD scaffolding where a test would just re-assert Rails' own routing with near-zero defect-catching value. Scope is closing these 14 named files, not an open-ended percentage target.

Sequenced after TASK-52/53/54 per explicit user direction (2026-08-16): "I'm open to the recommended #1 then in sequence. I'm not looking for everything to be done in one go."
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Each of the 14 named files has at least one spec covering its primary behavior (not just a smoke 'renders successfully' test where the action has real branching logic)
- [x] #2 Full suite still passes with 0 failures after additions
- [x] #3 No new file added to this list in the process (i.e. don't introduce new untested code while writing these specs)
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added at least one behavior-covering spec (not smoke-only) for each of the 14 named files:

- pages_controller.rb -> spec/requests/pages_spec.rb
- admin/extraction_rules_controller.rb -> spec/requests/admin/extraction_rules_spec.rb
- api/v0/sources_controller.rb -> spec/requests/api/v0/sources_spec.rb
- models_controller.rb -> spec/requests/models_spec.rb
- admin/documents_controller.rb -> spec/requests/admin/documents_spec.rb
- admin/interview_questions_controller.rb -> spec/requests/admin/interview_questions_spec.rb
- admin/pipeline_filters_controller.rb -> spec/requests/admin/pipeline_filters_spec.rb (route was missing entirely -- controller+view existed but were unroutable dead code; added `resources :pipeline_filters, only: [:index]`)
- job_lifecycle/expiry_sweep_job.rb -> spec/jobs/job_lifecycle/expiry_sweep_job_spec.rb
- admin/interview_sessions_controller.rb -> spec/requests/admin/interview_sessions_spec.rb
- api/v0/geo_controller.rb -> spec/requests/api/v0/geo_spec.rb
- solid_queue_maintenance/stale_job_pruner.rb -> spec/services/solid_queue_maintenance/stale_job_pruner_spec.rb
- admin/pipeline_prompts_controller.rb -> spec/requests/admin/pipeline_prompts_spec.rb
- job_boards/strategy_agent.rb -> spec/agents/job_boards/strategy_agent_spec.rb
- admin/skills_controller.rb -> spec/requests/admin/skills_spec.rb

One real bug found and fixed along the way: Admin::DocumentsController#index eager-loaded :job_boards_query via .includes, but no view ever reads it -- Bullet flagged it as unused eager loading the first time a request spec actually hit that action. Dropped the unused include.

Full combined suite (spec + packages/ingestion/spec): 780 examples, 0 failures, 94.31% line coverage (up from 91.28%). Full-repo RuboCop: 684 files, 0 offenses. Brakeman: 0 warnings.
<!-- SECTION:FINAL_SUMMARY:END -->
