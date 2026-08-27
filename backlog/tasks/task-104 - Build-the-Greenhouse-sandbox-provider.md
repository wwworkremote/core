---
id: TASK-104
title: Build the Greenhouse sandbox provider
status: To Do
assignee: []
created_date: '2026-08-27 17:25'
labels:
  - architecture
  - sandbox-provider
dependencies: []
documentation:
  - docs/architecture/sandbox-provider.md
priority: high
type: feature
ordinal: 200
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Full design in docs/architecture/sandbox-provider.md -- read the whole doc before starting, especially "Which provider first, and why" (Greenhouse, not LinkedIn/Workday -- mirrors TASK-78's real #application-form selector, simplest of the four target providers) and "Shape".

Build: Sandbox::PostingsController + Sandbox::ApplicationsController, a fake Greenhouse-shaped job posting page and apply form (real field ids/classes/structure mirroring what TASK-78's extension listener already targets, placeholder content -- never a copy of a real employer's real posting), a fake submit endpoint that mints job_post_id at page load and ats_application_id only at confirmation (deliberately exercising HandshakeCheck's required vs required_after_submit distinction, not just the easy always-present case).

Environment-gated hard: the route must not exist (not just 403) unless Rails.env.local?. The extension's own provider-recognition list must be gated the same way, so a build with this wired in can never mistake a real site for the fixture or vice versa.

Open question in the doc, needs a decision before/during implementation: does this live under app/ (visible, manually drivable in a browser) or spec/ (pure test infrastructure)? Doc leans toward app/ for the extra visibility during development -- not decided, implementer should raise if it matters.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Sandbox posting + apply flow is reachable at a route only in development/test, confirmed unreachable (route doesn't exist, not just forbidden) when RAILS_ENV=production
- [ ] #2 Form field ids/classes match what TASK-78's real #application-form listener already targets in the extension
- [ ] #3 job_post_id is present from page load; ats_application_id only appears after a fake submit reaches the confirmation step
- [ ] #4 The extension's provider-recognition list only includes wwworkremote.localhost under the same environment gate as the Rails route
- [ ] #5 No real employer's real posting content is copied into the fixture
<!-- AC:END -->
