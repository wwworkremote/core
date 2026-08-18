---
id: TASK-37.4
title: Research candidate new job-board providers for extension coverage
status: Done
assignee: []
created_date: '2026-08-13 17:41'
updated_date: '2026-08-18 20:37'
labels: []
milestone: m-1
dependencies: []
modified_files:
  - docs/extension-workflow.md
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
- [x] #1 Each candidate (Workable, iCIMS, BambooHR, Work at a Startup, Otta, Himalayas) is checked against at least one real live posting for: JSON-LD presence and whether it actually matches the page (not a feed-dump like RemoteOK's), and if JSON-LD is thin/absent, whether stable non-hashed selector hooks exist
- [x] #2 A short written recommendation is produced: which candidates are worth adding and in what priority order, which aren't worth it and why, based on what was actually observed on the live pages
- [x] #3 The recommendation is recorded (e.g. as a comment on this task or a short note in docs/extension-workflow.md) so TASK-37.5 can act on it without re-doing this research
- [x] #4 No changes are made to extension/content.js or manifest.json in this task
<!-- AC:END -->

## Comments

<!-- COMMENTS:BEGIN -->
created: 2026-08-18 20:37
---
Recommendation (live-checked 2026-08-18, full detail + evidence in docs/extension-workflow.md #9): priority order for TASK-37.5 is (1) jobs.rubyonrails.org -- clean matching JSON-LD, single-tenant, 100% Rails-relevant, added mid-session per user request; (2) Workable -- clean JSON-LD confirmed on 2 tenants (Rokt, GOVX), plenty of Staff/Senior SWE roles; (3) Himalayas -- clean JSON-LD confirmed on 2 tenants, but broader/mixed role types; (4) iCIMS -- JSON-LD confirmed and role mix is senior/enterprise, BUT the whole posting renders inside a same-origin iframe (`#icims_content_iframe`), needing `all_frames: true` + iframe-aware extraction, unlike every current provider -- flag as a real implementation decision, not a copy-paste; (5) Work at a Startup -- no JSON-LD, no data-* hooks, only a parseable-but-fragile 'Title at Company' h1 pattern (WeWorkRemotely-tier effort), but excellent Staff/Senior YC role fit makes it worth it. NOT recommended: BambooHR (JSON-LD works on 2/2 tenants but both were a dental practice and a nonprofit -- SMB/general employer base, near-zero engineering role yield against RoleFamily). DROP from list entirely: Otta -- rebranded/consolidated into Welcome to the Jungle (otta.com redirects to uk.welcometothejungle.com, confirmed via site footer); not evaluated as a fresh candidate here, out of scope. AC4 held: only docs/extension-workflow.md changed, no extension/content.js or manifest.json edits.
---
<!-- COMMENTS:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Live-checked all 6 named candidates (Workable, iCIMS, BambooHR, Work at a Startup, Otta, Himalayas) plus jobs.rubyonrails.org (added per user request mid-session) against real postings. Findings and priority-ordered recommendation recorded in docs/extension-workflow.md section 9 and as a task comment, so TASK-37.5 can act without redoing the research.

Priority order: jobs.rubyonrails.org > Workable > Himalayas > iCIMS (flagged: content lives in a same-origin iframe, needs all_frames + iframe-aware extraction -- a real design decision, unlike any current provider) > Work at a Startup (flagged: no JSON-LD, fragile h1-parsing needed, but worth it for role fit). Not recommended: BambooHR (JSON-LD works but observed tenants had near-zero engineering-role fit). Dropped entirely: Otta, which has rebranded/consolidated into Welcome to the Jungle and no longer exists as a distinct board.

No extension code touched (verified via git status) -- only docs/extension-workflow.md changed, satisfying AC4.
<!-- SECTION:FINAL_SUMMARY:END -->
