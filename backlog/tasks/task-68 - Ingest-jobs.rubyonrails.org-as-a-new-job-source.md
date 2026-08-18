---
id: TASK-68
title: Ingest jobs.rubyonrails.org as a new job source
status: To Do
assignee: []
created_date: '2026-08-18 16:06'
labels:
  - ingestion
  - sources
dependencies: []
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
- [ ] #1 New source seeded (db/seeds.rb) for jobs.rubyonrails.org with a source_id ingestion can key off of
- [ ] #2 Ingestion path chosen (RSS feed vs. HTML scrape) and documented as a decision, with root-cause check per above flag before copying an existing Fetcher pattern
- [ ] #3 New postings from this source appear in JobPosting with source_id set and are visible via existing job_postings#index filters
- [ ] #4 Cooldown/schedule registered in config/initializers/ingestion_adapters.rb consistent with existing Feed-type sources
<!-- AC:END -->
