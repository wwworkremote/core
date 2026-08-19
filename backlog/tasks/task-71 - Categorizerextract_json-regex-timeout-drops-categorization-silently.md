---
id: TASK-71
title: Categorizer#extract_json regex timeout drops categorization silently
status: To Do
assignee: []
created_date: '2026-08-19 15:04'
labels: []
dependencies: []
references:
  - packages/ingestion/app/services/job_boards/categorizer.rb
priority: medium
type: bug
ordinal: 84000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Found by a pipeline-health audit pass. `packages/ingestion/app/services/job_boards/categorizer.rb:74` — `response.match(/\{.*\}/m)&.to_s` in `extract_json` is hitting `Regexp::TimeoutError` repeatedly against long/messy LLM output: greedy `.*` between `{`/`}` in multiline mode is classic catastrophic-backtracking territory. Observed 4 times in one day (Aug 19: 12:38, 12:58, 13:16, 14:05 UTC) plus once Aug 17, silently dropping categorization for JobPosting ids 5572, 5923, 5927, 5946, 6002 (and presumably more historically). Fix: bound the match (e.g. a non-greedy pattern, a length cap before matching, or a proper JSON-extraction approach instead of regex against arbitrary LLM prose).
<!-- SECTION:DESCRIPTION:END -->
