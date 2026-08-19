---
id: TASK-71
title: Categorizer#extract_json regex timeout drops categorization silently
status: To Do
assignee: []
created_date: '2026-08-19 15:04'
updated_date: '2026-08-19 20:53'
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

**Second data point, same day**: 5 of 6 spec failures in a full-suite pre-commit hook run (878 examples) were all in `packages/ingestion/spec/services/job_boards/categorizer_spec.rb` -- all passed cleanly on an immediate isolated rerun (7 examples, 0 failures). This is consistent with the same timeout-prone regex being more likely to actually time out under full-suite CPU contention than when running alone -- i.e. this may not be pure test-order pollution (unlike the TASK-70 cluster) but a real manifestation of this exact bug being more reproducible under load. Worth prioritizing before it starts blocking commits regularly.
<!-- SECTION:DESCRIPTION:END -->
