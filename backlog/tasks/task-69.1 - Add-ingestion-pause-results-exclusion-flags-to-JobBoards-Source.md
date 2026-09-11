---
id: TASK-69.1
title: 'Add ingestion-pause + results-exclusion flags to JobBoards::Source'
status: Done
assignee: []
created_date: '2026-08-19 01:58'
updated_date: '2026-08-19 02:07'
labels: []
dependencies: []
modified_files:
  - >-
    db/migrate/20260819020154_add_ingestion_paused_and_excluded_from_results_to_job_boards_sources.rb
  - db/schema.rb
  - packages/ingestion/app/models/job_boards/source.rb
  - packages/ingestion/app/services/data_acquisition_manager.rb
  - app/controllers/data_fetchers_controller.rb
  - app/controllers/admin/sources_controller.rb
  - app/views/data_fetchers/index.html.erb
  - app/views/admin/sources/show.html.erb
  - config/routes.rb
  - spec/requests/data_fetchers_spec.rb
  - spec/requests/admin/sources_spec.rb
parent_task_id: TASK-69
priority: high
type: feature
ordinal: 79000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Two independent booleans on `JobBoards::Source` (or repurpose the existing dead `aasm_state` column for the pause state — see TASK-69):
- ingestion pause/disable, surfaced as a "Disable" action on `/data_fetchers` next to the existing Run/Force buttons (`app/views/data_fetchers/index.html.erb:44,54`; controller `app/controllers/data_fetchers_controller.rb`)
- results-exclusion flag, surfaced as a toggle on `/admin/sources/:id` (`app/controllers/admin/sources_controller.rb` is currently index/show only — needs an update action; view `app/views/admin/sources/show.html.erb`)

Fix the pre-existing bug at `app/views/admin/sources/show.html.erb:33` (renders `@source.payload`, which doesn't exist on this model — always shows `{}`) while touching this view.

Ingestion-pause must gate wherever `DataAcquisitionManager` currently only checks `SystemSetting.paused?` (global) — add a per-source check alongside it, not instead of it.
<!-- SECTION:DESCRIPTION:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added two independent booleans to `JobBoards::Source`: `ingestion_paused` and `excluded_from_results` (this task only wires the flags + admin UI; TASK-69.2 makes `excluded_from_results` actually filter job posting results).

- `/data_fetchers` now has a Disable/Enable button per source row alongside Run/Force. `DataAcquisitionManager.run` blocks a normal run when `ingestion_paused` (Force still overrides, matching the existing global-pause override semantics).
- `/admin/sources/:id` (the exact URL the user pointed at) now has both toggles in an "Ingestion & Results" panel, replacing the old "Payload" panel that was silently always rendering `{}` — `JobBoards::Source` has no `payload` attribute; that belonged to the unrelated `Source` model.
- Verified end-to-end in-browser against real data: disabled Arbeitnow from `/data_fetchers`, confirmed it showed "Disabled" with Run greyed out, confirmed the same state on `/admin/sources/17`, then re-enabled it (ingestion should stay ON per the user's clarified intent to keep aggregating — only *results* should be excluded, which is TASK-69.2's job).
- 15 new/updated request-spec examples, all passing. Full suite: 622+ examples, 0 failures before this task; re-verify after 69.2.
<!-- SECTION:FINAL_SUMMARY:END -->
