---
id: TASK-50
title: Add backlog-audit and direct-hiring-board-verify skills/agent/conventions doc
status: Done
assignee: []
created_date: '2026-08-16 13:33'
updated_date: '2026-08-16 13:38'
labels: []
dependencies: []
references:
  - CLAUDE.md
  - docs/agents/bin-script-conventions.md
  - .claude/skills/backlog-audit/SKILL.md
  - .claude/agents/backlog-audit-agent.md
  - .claude/skills/direct-hiring-board-verify/SKILL.md
  - bin/verify_board
priority: low
type: chore
ordinal: 56000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Session tooling improvement: codified two manual processes repeated this session into discoverable Claude Code skills, plus one doc capturing a recurring bug-class convention.

1. `docs/agents/bin-script-conventions.md` -- documents the non-transactional test-DB write pattern that independently broke TASK-35 twice (bin/verify_ingestion, then rake quality's InsightIngester), with the two concrete fix shapes (rollback transaction vs. env-guarded call site) so a future bin/ script doesn't reintroduce it a third time.
2. `.claude/skills/backlog-audit/SKILL.md` -- codifies the staleness/duplicate-detection process used to close TASK-10 (duplicate of TASK-35) and TASK-33 (already fixed 3 months before it was filed, just never linked back) -- cross-reference a bug task's References against git history before trusting its description.
3. `.claude/agents/backlog-audit-agent.md` -- background-capable variant of the same skill, for a context-isolated audit pass (mirrors the existing pipeline-health-agent pattern).
4. `.claude/skills/direct-hiring-board-verify/SKILL.md` + `bin/verify_board` -- generalizes the manual `bin/rails runner` one-liners used to test the ADP/Workday adapters this session into a reusable script covering all four board-based adapters (adp/workday/greenhouse/lever), so onboarding a new direct-hiring company (the repo's stated ingestion priority) has a fast verify-before-seed step instead of waiting for the next scheduled fetch cycle.

All three doc/skill entries cross-referenced from CLAUDE.md's Agent skills section, matching the existing pointer-style convention (issue-tracker, triage-labels, domain docs).
<!-- SECTION:DESCRIPTION:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Built and verified live, not just written:
- `bin/verify_board` tested against a real board (`adp corpfollettexternal`) in development -- runs clean, correctly reports 0 new rows (Follett genuinely has no open reqs, confirmed earlier this session), and refuses to run under RAILS_ENV=test with a clear message pointing at the new conventions doc. RuboCop clean.
- Workday's hash-shaped board argument (`{tenant, wd, site}`) verified via static parse trace rather than a live run, per explicit user preference not to trigger that particular live network call this session.
- `backlog-audit` skill's process is exactly what was just used live to close TASK-10 and TASK-33 this session -- not speculative, a direct writeup of a proven method.

No new gem/npm/brew/mise installs were added -- audited `.tool-versions` (already pins ruby 4.0.6 + nodejs 24.14.0), `Gemfile`, and `package.json` and found no missing dependency grounded in actual friction hit this session. The one real environment gap found earlier (missing Playwright chromium binary) was a project-local browser download (`node_modules/.bin/playwright install chromium`), not a package-manager omission, and was already fixed and documented in TASK-45.

Follow-up (2026-08-16, same session): added docs/agents/bin-scripts.md -- a full index of every bin/ script with a one-line purpose and when to use it, so 'is there already a tool for this' has a fast answer instead of a repo search or a new ad-hoc bin/rails runner one-liner. Referenced from CLAUDE.md alongside the other two entries. Audited every bin/* script's existing --help/usage text while building it: bin/wwwr, bin/verify_board, bin/verify_promote.rb, bin/services, and bin/apply already have clear usage output; the remaining scripts (bin/dev, bin/ci, bin/jobs, bin/fetch-jobs, bin/trigger_scrapers.rb, etc.) don't take arguments in a way that needs one, or are launchd entry points not meant to be run by hand -- didn't add --help flag handling to those, since it would mean changing argument-parsing contracts in scripts I didn't write without a concrete request to do so.
<!-- SECTION:FINAL_SUMMARY:END -->
