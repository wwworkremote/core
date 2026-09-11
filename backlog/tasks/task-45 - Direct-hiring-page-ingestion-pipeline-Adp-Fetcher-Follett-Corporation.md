---
id: TASK-45
title: 'Direct-hiring-page ingestion pipeline: Adp::Fetcher (Follett Corporation)'
status: Done
assignee: []
created_date: '2026-08-15 18:28'
labels:
  - ingestion
  - direct-source
dependencies: []
modified_files:
  - packages/ingestion/app/services/adp/fetcher.rb
  - packages/ingestion/app/services/adp/token_minter.rb
  - packages/ingestion/app/services/job_boards/syncer/attribute_mapper.rb
  - packages/ingestion/spec/services/job_boards/syncer/attribute_mapper_spec.rb
  - config/initializers/ingestion_adapters.rb
priority: medium
type: feature
ordinal: 51000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Requested: find open Follett Library Services postings and get them ingested/processed, bypassing generic job boards -- and build the mechanism as a reusable pipeline for future direct-hiring-page companies, not a one-off. Preference stated: deterministic/non-AI tooling for the bulk fetch-and-aggregate work, save AI for heavier discovery.

Investigation: Follett Library Services is now branded "Follett Content Solutions" and currently has zero open requisitions there and on BuiltIn (confirmed). All of Follett's corporate hiring (including Library/Content Solutions when it does post) runs through one shared ADP "myjobs.adp.com" career site (`corpfollettexternal`), same platform many other mid/large employers use for direct hiring.

That career site is a JS SPA with no real `<a href>` job links (Discovery's existing crawl-and-scrape approach can't work here) and its job-search REST API is gated by a session token minted client-side only -- no static API key. Reverse-engineered the flow via a live Playwright probe: load the career site once headlessly, capture the `myjobstoken` header off the page's own outgoing request, then call ADP's plain JSON OData endpoint directly (`.../job-requisitions/apply-custom-filters`) for full structured data (title, HTML description, location, requisition ID, posting date) -- no further scraping.
<!-- SECTION:DESCRIPTION:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Built `Adp::Fetcher` (packages/ingestion/app/services/adp/fetcher.rb) as a new AdapterRegistry entry ("adp"), mirroring the existing Greenhouse::Fetcher/Lever::Fetcher shape exactly: one `JobBoards::Query#data["boards"]` array of company career-site slugs, one `GranularFetchJob` per board, results land in `JobBoards::Document` via the existing `JobBoards::DocumentUpserter`, then flow through the existing `JobBoards::Syncer` into `JobPosting` like every other provider. **Adding a new ADP-hosted company going forward is a one-line data change (append its career-site slug to `boards`) -- zero code.**

- `Adp::TokenMinter` (packages/ingestion/app/services/adp/token_minter.rb): the only Playwright-dependent piece, split out to keep Fetcher focused. One headless page load per board mints the session token; everything after that is plain JSON over Faraday via the existing `JobBoards::Client`.
- `JobBoards::Syncer::AttributeMapper#map_adp` added (packages/ingestion/app/services/job_boards/syncer/attribute_mapper.rb) -- title/body/location/company/target_url/published_at from ADP's requisition JSON shape. Spec added (packages/ingestion/spec/services/job_boards/syncer/attribute_mapper_spec.rb).
- Registered in config/initializers/ingestion_adapters.rb as type "Direct" (cooldown 4h, matching the other API-style fetchers).
- Playwright's chromium binary was missing from this dev machine entirely (`playwright install chromium` fixed it) -- this had been silently breaking every existing crawl-discovery-based source (cord, builtin, remoteio, flexjobs, bestjobs, echojobs, roberthalf) in this environment, not just the new ADP path. Worth a follow-up check that CI/prod actually has it installed (bin/setup or a Dockerfile step) -- not verified in this session, flagging for anyone touching deploy.

**Live-verified end-to-end** against Follett's real career site (`corpfollettexternal`): 6 real open Follett Corporation requisitions fetched, mapped, and synced into real `JobPosting` rows (Buyer Assistant, Team Lead Python/Django Engineer, Student Marketing Director, Retail Construction Project Manager, Lead Business Intelligence Engineer, Product Onboarding Specialist) -- all passed `JobBoards::QualityFilter` (status "none", not ignored). None were Library-Services-titled roles because Follett Content Solutions (the current name for Library Services) has zero open reqs right now -- confirmed independently via BuiltIn (`builtin.com/company/follett-content-solutions-llc/jobs`: "No jobs to discover at this time"). The pipeline will pick up a Library Services posting automatically the moment Follett opens one, since it reads the same shared corporate career site.

603+ existing specs unaffected; new/changed files pass RuboCop clean.
<!-- SECTION:FINAL_SUMMARY:END -->
