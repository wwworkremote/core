---
id: TASK-37.4
title: Research candidate new job-board providers for extension coverage
status: To Do
assignee: []
created_date: '2026-08-13 17:41'
labels: []
milestone: m-1
dependencies: []
parent_task_id: TASK-37
priority: medium
type: spike
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The extension currently supports 12 providers (see `extension/content.js`'s `PROVIDERS` object and `docs/extension-workflow.md`). Candidates worth evaluating for new coverage, identified at the end of a fidelity-audit session: Workable (apply.workable.com), iCIMS, BambooHR career pages, Work at a Startup (Y Combinator, workatastartup.com), Otta, and Himalayas. None of these have been checked live -- this is reputation-based guessing, not verified.

Selection criteria that proved out this session (see the parent task): strongly prefer providers with reliable schema.org JobPosting JSON-LD -- that tier needs near-zero CSS maintenance and is far less fragile than hand-rolled selectors. Among comparable options, prefer boards more likely to carry the kind of roles the user is actually targeting (mid-to-senior engineering, per the existing RoleFamily taxonomy in `app/services/role_family.rb`) over one that's just easy to scrape.

This task is research only -- no extraction code should be written here. The output is a recommendation that a follow-up task (already scaffolded as TASK-37.5) will implement.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Each candidate (Workable, iCIMS, BambooHR, Work at a Startup, Otta, Himalayas) is checked against at least one real live posting for: JSON-LD presence and whether it actually matches the page (not a feed-dump like RemoteOK's), and if JSON-LD is thin/absent, whether stable non-hashed selector hooks exist
- [ ] #2 A short written recommendation is produced: which candidates are worth adding and in what priority order, which aren't worth it and why, based on what was actually observed on the live pages
- [ ] #3 The recommendation is recorded (e.g. as a comment on this task or a short note in docs/extension-workflow.md) so TASK-37.5 can act on it without re-doing this research
- [ ] #4 No changes are made to extension/content.js or manifest.json in this task
<!-- AC:END -->
