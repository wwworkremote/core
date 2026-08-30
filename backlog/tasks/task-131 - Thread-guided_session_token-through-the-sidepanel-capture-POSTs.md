---
id: TASK-131
title: Thread guided_session_token through the sidepanel capture POSTs
status: To Do
assignee: []
created_date: '2026-08-30 02:10'
labels:
  - application-capture-datalake
  - 'wayfinder-map:doc-7'
dependencies:
  - TASK-129
references:
  - docs/adr/010-link-to-application-capture-and-the-datalake.md
  - extension/sidepanel.js
  - extension/content.js
priority: low
type: feature
ordinal: 147000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Follow-up to TASK-129 (correlation spine, ADR 010 §2).

TASK-129 wired the Rails side: `application_field_answers`, `application_field_mappings`, `application_field_observations`, and `extension_error_events` all accept a top-level `guided_session_token` param and persist it; `content.js` sends it on the `application_field_answers` POST (the token is already in scope there via the page URL param).

Still missing: `extension/sidepanel.js` builds the `application_field_observations` (sidepanel.js:~647) and `application_field_mappings` (sidepanel.js:~1521) POSTs, and the sidepanel does not currently know the guided session token — `content.js:32` reads it from the page URL but never forwards it. Needs content -> sidepanel message passing (or the sidepanel querying the active tab URL) so those two POSTs carry the token during a guided session.

Also `background.js:405` posts `extension_error_events` without the token.

## Scope

- Forward `guidedSessionToken` from content.js to sidepanel.js (message on session start / on the existing state sync).
- Include `guided_session_token` in the observations + mappings POST bodies in sidepanel.js when present.
- Include it in the background.js extension_error_events POST when the failing context is a guided session.
- `extension/manifest.json` version bump.

## Out of scope

- The datalake asset endpoint (TASK-126) — separate transport.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 content.js forwards the guided session token to sidepanel.js; a documented manual check or an extension test confirms it arrives
- [ ] #2 sidepanel.js includes guided_session_token in the application_field_observations and application_field_mappings POST bodies when a guided session is active
- [ ] #3 background.js includes guided_session_token in the extension_error_events POST when the error occurred during a guided session
- [ ] #4 extension/manifest.json version bumped; rubocop + brakeman unaffected (no Rails change expected)
<!-- AC:END -->
