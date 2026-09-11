---
id: TASK-65
title: Add primary nav entry for admin analytics / extraction-rule status
status: Done
assignee: []
created_date: '2026-08-17 23:02'
updated_date: '2026-08-27 18:04'
labels:
  - ux
  - navigation
dependencies: []
modified_files:
  - app/views/layouts/application.html.erb
  - config/locales/en.yml
type: enhancement
ordinal: 70000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Ahoy visit landing-page data shows repeated direct/typed navigation straight to raw endpoints -- `/mounts/analytics` (the ahoy_captain-mounted analytics engine, see config/routes.rb:338), `/api/extraction_rules?provider=X`, `/api/companies/search?q=X` -- as the first page of a fresh browser visit, rather than being reached by clicking through the app's own navigation (app/views/layouts/application.html.erb's header nav currently only links Dashboard/Companies/Job Postings/Saved Jobs).

This is a discoverability gap: the user already knows these surfaces exist and goes straight to the URL from memory, which suggests they should be one click away from the primary nav instead of requiring a remembered/bookmarked URL.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Primary nav includes a reachable link to the ahoy_captain analytics dashboard (mounted at /analytics)
- [x] #2 Primary nav or an admin submenu includes a reachable link to extraction-rule status per provider
- [x] #3 No change to the underlying analytics/extraction-rule endpoints themselves -- navigation only
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
AC#1 (analytics link) was already present in the admin dropdown -- only AC#2 was missing. Added an "Extraction Rules" link (admin_extraction_rules_path) to both the desktop admin dropdown and the mobile nav menu in app/views/layouts/application.html.erb, plus the corresponding en.yml locale key. No endpoint changes.
<!-- SECTION:FINAL_SUMMARY:END -->
