---
id: TASK-104
title: Build the Greenhouse sandbox provider
status: Done
assignee: []
created_date: '2026-08-27 17:25'
updated_date: '2026-08-27 18:55'
labels:
  - architecture
  - sandbox-provider
dependencies: []
documentation:
  - docs/architecture/sandbox-provider.md
modified_files:
  - config/routes.rb
  - app/controllers/sandbox/application_controller.rb
  - app/controllers/sandbox/postings_controller.rb
  - app/controllers/sandbox/applications_controller.rb
  - app/views/sandbox/postings/show.html.erb
  - app/views/sandbox/applications/create.html.erb
  - spec/requests/sandbox_spec.rb
  - extension/content.js
  - extension/manifest.json
  - extension/README.md
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
- [x] #1 Sandbox posting + apply flow is reachable at a route only in development/test, confirmed unreachable (route doesn't exist, not just forbidden) when RAILS_ENV=production
- [x] #2 Form field ids/classes match what TASK-78's real #application-form listener already targets in the extension
- [x] #3 job_post_id is present from page load; ats_application_id only appears after a fake submit reaches the confirmation step
- [x] #4 The extension's provider-recognition list only includes wwworkremote.localhost under the same environment gate as the Rails route
- [x] #5 No real employer's real posting content is copied into the fixture
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Built the Greenhouse sandbox provider per docs/architecture/sandbox-provider.md.

Rails side: Sandbox::PostingsController#show (GET /sandbox/postings/:id) mints
job_post_id at page load; Sandbox::ApplicationsController#create (POST
/sandbox/applications) mints ats_application_id only at confirmation. Both
routes live inside a top-level `if Rails.env.local?` block in config/routes.rb
so they don't exist at all (not 403) outside development/test -- verified in
spec/requests/sandbox_spec.rb by reloading routes with Rails.env stubbed to
"production" and asserting ActionController::RoutingError, plus a manual curl
check against the running dev server. The posting/apply views mirror the real
Greenhouse DOM shape TASK-78's extension listener already targets
(#application-form, question_<n> fields + labels, #demographic-section) with
obviously fictional "Acme Sandbox Co" content -- no real employer content
copied in.

Extension side: content.js's greenhouse provider match() now also recognizes
wwworkremote.localhost, but only when IS_LOCAL_BUILD is true (no update_url in
the extension's own manifest -- the standard native signal for "loaded
unpacked/dev", chosen since this extension has no build-time env flag and
isn't Web-Store-published today). Bumped manifest version 1.25.1 -> 1.26.0 per
project convention (new capability) and updated extension/README.md's version
line to match.

Judgment calls: (1) job_post_id/ats_application_id are exposed as
data-job-post-id/data-ats-application-id attributes plus visible confirmation
text rather than persisted anywhere -- the sandbox is intentionally stateless
(no model/migration), matching the doc's "smallest correct shape" and the fact
Phase A's automatic-capture harness that would consume these is explicitly
deferred, not part of this task. (2) The extension's "environment gate" has no
existing precedent in this codebase (no NODE_ENV/build-flag concept for the
unpacked extension) -- used the update_url-absence check as the closest native
equivalent of Rails.env.local? on the extension side.

Verified: isolated spec/requests/sandbox_spec.rb (4 examples, 0 failures),
eslint via `yarn lint:extension` (clean), rubocop + erb_lint on all touched
Ruby/ERB files (clean), full `bundle exec rspec` (901 examples, 0 failures),
and a manual curl round-trip against the running dev server confirming
job_post_id present pre-submit and ats_application_id only appearing on the
confirmation response.
<!-- SECTION:FINAL_SUMMARY:END -->
