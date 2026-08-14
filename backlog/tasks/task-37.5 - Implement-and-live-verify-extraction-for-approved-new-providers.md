---
id: TASK-37.5
title: Implement and live-verify extraction for approved new providers
status: To Do
assignee: []
created_date: '2026-08-13 17:41'
labels: []
milestone: m-1
dependencies:
  - TASK-37.4
parent_task_id: TASK-37
priority: medium
type: feature
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Depends on TASK-37.4's recommendation -- read it before starting; it will name which providers to add and in what order.

Follow this session's established pattern exactly (see the parent task TASK-37 and `docs/extension-workflow.md` for the full rationale): for each approved provider, live-inspect the real DOM before writing any selector, prefer schema.org JobPosting JSON-LD when present (and verify it actually matches the page being viewed -- don't assume, RemoteOK's JSON-LD turned out to be an unrelated feed dump), prefer stable/semantic hooks (data-* attributes, hostname or URL conventions, plainly-named classes) over hashed CSS-Modules classes when writing CSS-tier fallbacks, and verify against at least 2 real postings/tenants where the platform is multi-tenant.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Each provider approved by TASK-37.4's research is added to extension/content.js's PROVIDERS object and to manifest.json's host_permissions and content_scripts.matches
- [ ] #2 Each new provider extracts title/company/location/description reliably, plus salary/employment_type/remote where the source discloses them
- [ ] #3 Each new extractor is verified against at least one real live posting (title/company/location/description confirmed correct) before being considered done
- [ ] #4 manifest.json version is bumped following the project's semver rule (new provider = new capability = minor bump)
- [ ] #5 docs/extension-workflow.md's provider list/components section is updated to include the new providers
- [ ] #6 docs/architecture/openapi.yaml is updated if the new providers require any request/response shape not already covered
- [ ] #7 node --check and npm run lint:extension pass on all modified extension files
<!-- AC:END -->
