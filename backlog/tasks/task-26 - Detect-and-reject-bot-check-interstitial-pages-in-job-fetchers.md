---
id: TASK-26
title: Detect and reject bot-check/interstitial pages in job fetchers
status: Done
assignee: []
created_date: '2026-07-27 22:15'
updated_date: '2026-07-28 01:27'
labels: []
dependencies: []
priority: high
ordinal: 25000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
JobFetchers::PageFetch/CanonicalJobExtractor don't detect when a fetch is served a bot-detection wall instead of the real page. Confirmed 54 fake JobPosting rows in job_postings.title: 'We're signing you in' (51) and 'Additional Verification Required' (3), all sourced via Indeed email links -- Indeed is challenging the Playwright fetcher and the extractor happily saves the challenge page's title/company as if it were a real job. Add detection (known interstitial title strings, or absence of expected job-posting markup) that fails the fetch instead of creating a JobPosting. Also related: CanonicalJobExtractor grabs the generic search-results-page title ('ruby jobs in Remote') instead of the specific job title for at least the Indeed URL pattern -- same extractor, worth fixing alongside this.
<!-- SECTION:DESCRIPTION:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Added JobFetchers::CanonicalJobExtractor#interstitial? -- checks extracted title against a denylist of observed bot-check copy ('signing you in', 'additional verification required', plus common Cloudflare/generic patterns) and returns nil instead of a data hash when matched. Updated all 5 call sites to handle nil: email_ingestion/importer.rb and scraper/enricher.rb (x2) now 'return unless job_data/data'; content_enrichment_job.rb marks crawl_status: enrichment_blocked instead of crashing into the generic rescue; api/job_postings_controller.rb guards with 'job_data &&'. Verified live: known bad titles ('We are signing you in', 'Additional Verification Required') both return nil, a real job title extraction is unaffected. rubocop offenses present are all pre-existing complexity/length debt on methods touched with only 1-2 line guard clauses (same pattern as embedder.rb/importer.rb earlier this session), not new. Relevant specs (enricher_spec, importer_spec) pass 4/4.
<!-- SECTION:NOTES:END -->
