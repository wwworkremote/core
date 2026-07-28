---
id: TASK-26
title: Detect and reject bot-check/interstitial pages in job fetchers
status: To Do
assignee: []
created_date: '2026-07-27 22:15'
labels: []
dependencies: []
priority: high
ordinal: 25000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
JobFetchers::PageFetch/CanonicalJobExtractor don't detect when a fetch is served a bot-detection wall instead of the real page. Confirmed 54 fake JobPosting rows in job_postings.title: 'We're signing you in' (51) and 'Additional Verification Required' (3), all sourced via Indeed email links -- Indeed is challenging the Playwright fetcher and the extractor happily saves the challenge page's title/company as if it were a real job. Add detection (known interstitial title strings, or absence of expected job-posting markup) that fails the fetch instead of creating a JobPosting. Also related: CanonicalJobExtractor grabs the generic search-results-page title ('ruby jobs in Remote') instead of the specific job title for at least the Indeed URL pattern -- same extractor, worth fixing alongside this.
<!-- SECTION:DESCRIPTION:END -->
