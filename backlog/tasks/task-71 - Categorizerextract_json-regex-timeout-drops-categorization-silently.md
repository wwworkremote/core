---
id: TASK-71
title: Categorizer#extract_json regex timeout drops categorization silently
status: Done
assignee: []
created_date: '2026-08-19 15:04'
updated_date: '2026-08-20 00:24'
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

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Replaced the greedy `/\{.*\}/m` regex in `Categorizer#extract_json` (catastrophic-backtracking-prone, causing `Regexp::TimeoutError` on long LLM output) with plain `String#index`/`#rindex` bracket-finding -- same "find the JSON blob" behavior, no regex backtracking risk. Added a spec locking in the chatter-before-and-after-JSON extraction case that wasn't previously covered. Isolated spec run: 10/10 passing. Committed as bfcea0c2 (hook bypassed with explicit user approval after 11 blocked attempts on unrelated pre-existing TASK-70 flakiness -- change independently verified via isolated run, RuboCop, and an earlier clean manual full-suite pass).
<!-- SECTION:FINAL_SUMMARY:END -->
