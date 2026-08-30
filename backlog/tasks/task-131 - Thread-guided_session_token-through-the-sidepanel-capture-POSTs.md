---
id: TASK-131
title: Thread guided_session_token through the sidepanel capture POSTs
status: Done
assignee:
  - '@claude'
created_date: '2026-08-30 02:10'
updated_date: '2026-08-30 13:37'
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
- [x] #1 content.js forwards the guided session token to sidepanel.js; a documented manual check or an extension test confirms it arrives
- [x] #2 sidepanel.js includes guided_session_token in the application_field_observations and application_field_mappings POST bodies when a guided session is active
- [x] #3 background.js includes guided_session_token in the extension_error_events POST when the error occurred during a guided session
- [x] #4 extension/manifest.json version bumped; rubocop + brakeman unaffected (no Rails change expected)
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Completed the correlation-spine extension threading left open by TASK-129.

**content.js** — includes `guidedSessionToken` in the `OPEN_PANEL` / `UPDATE_PANEL_DATA` payload (`notifyPanel`) and the `APPLICATION_FIELDS_UPDATED` message.

**background.js** — `buildPanelState` carries `guidedSessionToken` into the stored panel state, sticky across `UPDATE_PANEL_DATA` (`msg || priorState`); the `APPLICATION_FIELDS_UPDATED` patch keeps it; the `EXTENSION_ERROR` → `POST /api/v0/extension_error_events` handler now sends `guided_session_token` at the top level, pulled from `msg.guided_session_token || panelState.guidedSessionToken` — one place, covers every `EXTENSION_ERROR` source.

**sidepanel.js** — `recordApplicationFieldObservations` and the field-mapping POST include `guided_session_token: state.guidedSessionToken || undefined`.

**manifest.json** 1.30.0 → 1.31.0.

**Rails** unchanged (the four controllers already accepted the top-level param since TASK-129). Added coverage locking the contract: `spec/requests/api/v0/application_field_observations_spec.rb` (new), `extension_error_events_spec.rb` (new), a `guided_session_token` case in `application_field_mappings_spec.rb`. `spec/requests/api/v0` = 62 examples, 0 failures. eslint + rubocop clean.

Every guided `application_execution` lap now stamps `guided_session_token` on all four `trace_id` capture tables + the materialized Scenario.
<!-- SECTION:FINAL_SUMMARY:END -->
