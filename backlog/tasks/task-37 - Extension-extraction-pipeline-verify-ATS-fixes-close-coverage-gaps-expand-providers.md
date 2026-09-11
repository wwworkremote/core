---
id: TASK-37
title: >-
  Extension extraction pipeline: verify ATS fixes, close coverage gaps, expand
  providers
status: To Do
assignee: []
created_date: '2026-08-13 17:40'
labels: []
milestone: m-1
dependencies: []
priority: high
type: task
ordinal: 42000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
## Context for a fresh session

The Chrome extension (`extension/`) captures job postings from third-party boards into WWWorkRemote via a content script (`extension/content.js`) → background service worker → side panel pipeline. Full architecture, sequence diagrams, and contracts are documented in `docs/extension-workflow.md` (also rendered live at `/admin/extension_workflow`) and `docs/architecture/openapi.yaml` -- read those first, they are the canonical reference, not this task.

A prior session did a systematic fidelity audit across all supported providers and found + fixed real, live-verified bugs in: Dice (missing fields), WeWorkRemotely (full site redesign broke every selector), RemoteOK (a serious bug -- the page embeds JSON-LD for its entire job feed, and the extractor was blindly trusting the first match, which could be a completely unrelated posting), and all five ATS platforms (Greenhouse, Lever, Workday, Ashby, SmartRecruiters) -- each had at least one stale/wrong selector (e.g. Workday's company selector was silently reading the *location* value due to a reused hashed CSS class). The fix pattern that worked every time: live-inspect the real DOM via browser automation, find a stable hook (a `data-*` attribute, a hostname/URL convention, a plainly-named class, or JSON-LD), verify it against 2+ real postings before writing the extractor -- never guess.

manifest.json is currently at 1.8.0. Extension version semver rule is in the project's `CLAUDE.md`.

## Why this parent task exists

The fixes above were verified at different depths -- some got a full live capture+promote round trip, others only got capture (Lead creation), some only got standalone DOM-logic verification without confirming the extension actually activates on that host. Before adding new provider coverage, the existing 12 providers need to be brought to a consistent, trustworthy verification bar. Then coverage should grow.

## Suggested sequence (not a hard gate except where noted)

1. Verify the promote leg (capture -> submit -> JobPosting) for the 5 ATS providers -- only capture was proven for them.
2. Regression-check the "teach the extractor" picker flow and the LinkedIn/Indeed extractors against the current build -- several shared helpers were introduced/changed after those were last verified.
3. Live-verify and fix Adzuna and Wellfound -- the only two supported providers never checked against a real posting.
4. Research candidate new providers (does not touch code).
5. Implement + verify approved new providers (depends on 4's recommendation).
6. Reconcile docs/extension-workflow.md and the OpenAPI spec with final state -- do this last, or it'll need redoing.

Steps 1-3 are independent of each other and of 4-6; they don't need to happen in this exact order, just before new provider work starts, since there's little point expanding coverage on top of an unverified base.

## Non-negotiable working discipline (carried over from the session that found these bugs)

- Never write or trust a CSS selector without checking it against the real, live page first.
- Hashed/generated CSS classes (`.css-xxx`, `_section_hash_nn`) are never stable -- always find something else (data-* attribute, hostname/URL structure, JSON-LD, a plainly-named class).
- When JSON-LD is present, check whether it actually corresponds to the page being viewed (compare its title against the page's own H1/title) before trusting it -- some boards embed a whole feed's worth of JSON-LD on every page.
- Verify against at least 2 real postings/tenants where the platform is multi-tenant (Workday, SmartRecruiters, Ashby, Greenhouse) since one company's theme/customization can differ from another's.
- `node --check extension/*.js` and `npm run lint:extension` after every change; bump manifest.json version per CLAUDE.md's rule.
<!-- SECTION:DESCRIPTION:END -->
