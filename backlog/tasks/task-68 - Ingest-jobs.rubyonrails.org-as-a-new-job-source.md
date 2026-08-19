---
id: TASK-68
title: Ingest jobs.rubyonrails.org as a new job source
status: Done
assignee: []
created_date: '2026-08-18 16:06'
updated_date: '2026-08-19 18:13'
labels:
  - ingestion
  - sources
dependencies: []
modified_files:
  - packages/ingestion/app/services/rails_job_board/fetcher.rb
  - config/initializers/ingestion_adapters.rb
  - db/seeds.rb
  - packages/ingestion/app/services/job_boards/syncer/attribute_mapper.rb
  - packages/ingestion/spec/services/rails_job_board/fetcher_spec.rb
  - packages/ingestion/spec/services/job_boards/syncer/attribute_mapper_spec.rb
type: feature
ordinal: 77000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add jobs.rubyonrails.org (the official Rails job board) as an ingestion source -- flagged by the user as "the job board I've been looking for," a strong-fit source given the resume/skill profile this app is built around.

Site details (checked 2026-08-18): runs on a custom Rails app powered by "JobKit". Root path lists jobs with category (Senior/Mid-level/Junior) and employment-term (Full-time/Contract/Part-time/Internship/Freelance) filters. Individual postings are at `/jobs/[ID]-[slug]`. An RSS feed is available at https://jobs.rubyonrails.org/jobs.rss -- likely the lowest-friction ingestion path (no auth, structured, matches the existing "Feed" adapter type already used for arbeitnow/jobicy in config/initializers/ingestion_adapters.rb) versus scraping the HTML listing.

Flag for whoever picks this up: grepped the repo for the Fetcher classes config/initializers/ingestion_adapters.rb already registers (Arbeitnow::Fetcher, Jobicy::Fetcher, Greenhouse::Fetcher, Lever::Fetcher, Adzuna::Fetcher, Remotive::Fetcher, etc.) and found zero matching class definitions anywhere in app/ or lib/ -- the registry references constants that don't appear to exist in this codebase as of this commit. Worth confirming whether the app currently boots clean / whether Ingestion::AdapterRegistry.all is actually exercised anywhere before assuming any of these are a working reference implementation to copy.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 New source seeded (db/seeds.rb) for jobs.rubyonrails.org with a source_id ingestion can key off of
- [x] #2 Ingestion path chosen (RSS feed vs. HTML scrape) and documented as a decision, with root-cause check per above flag before copying an existing Fetcher pattern
- [x] #3 New postings from this source appear in JobPosting with source_id set and are visible via existing job_postings#index filters
- [x] #4 Cooldown/schedule registered in config/initializers/ingestion_adapters.rb consistent with existing Feed-type sources
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Resolved the original flag: `Ingestion::AdapterRegistry`'s Fetcher classes DO exist and DO work (verified live all session via /data_fetchers showing real timestamps) -- they just live under `packages/ingestion/app/services/`, not `app/`, which a plain `app/` grep missed. Confirmed the app boots clean and the registry is exercised.

**Decision (AC#2): RSS feed, not HTML scrape.** `https://jobs.rubyonrails.org/jobs.rss` returns clean structured XML (title/link/guid/pubDate/description, 18 items), no auth. Parsed with Nokogiri (already a Rails dependency -- no new gem; Ruby's stdlib `rss` library was tried first and rejected, it's a bundled gem not present in this Gemfile).

- `RailsJobBoard::Fetcher` mirrors `Arbeitnow::Fetcher`'s exact shape (ApiGuard, JobBoards::Client, Document dedup by signature).
- New `AttributeMapper#map_rubyonrails`: the feed has no structured company field -- titles are "{Role}[, remote] at {Company}", parsed via a title-suffix split (same pattern as the extension's WeWorkRemotely/Greenhouse fallback). Handles the feed's own data-quality garbage gracefully (a title with a literal duplicated "at Company at Company" still yields the correct company).
- Seeded (`db/seeds.rb`), registered in `ingestion_adapters.rb` (Feed type, 4h cooldown, matching Jobicy).
- **Verified live end-to-end**, not just unit-tested: ran the real fetcher against the real feed, synced the resulting Documents, confirmed 17 real JobPostings landed correctly -- e.g. "Senior Software Engineer - Business Platform (Ruby/Rails)" at Huntress, "Software Engineer, Growth" at Fleetio -- all `status: none` (visible), correct company/title/target_url. AC#3 (visible via job_postings#index filters) needed no new controller code: the existing generic `source_id`/status filtering already covers any source.
- 14 new spec examples (fetcher + attribute mapper), full suite 632 examples with 1 unrelated pre-existing flake (see TASK-70, confirmed passing in isolation, different file entirely).
<!-- SECTION:FINAL_SUMMARY:END -->
