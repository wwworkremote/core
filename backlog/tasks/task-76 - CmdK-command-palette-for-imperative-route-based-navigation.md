---
id: TASK-76
title: 'Cmd+K command palette for imperative, route-based navigation'
status: Done
assignee: []
created_date: '2026-08-19 20:54'
updated_date: '2026-08-19 21:25'
labels: []
dependencies: []
references:
  - app/views/layouts/application.html.erb
  - config/routes.rb
modified_files:
  - app/services/command_index.rb
  - app/javascript/controllers/command_palette_controller.js
  - app/views/layouts/application.html.erb
  - spec/services/command_index_spec.rb
  - spec/requests/navigation_spec.rb
priority: medium
type: feature
ordinal: 89000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
User's own experience: a Cmd+K workflow backed by a well-organized sitemap and clear domain structure is a very effective navigation pattern -- more direct than reconciling two visually different nav bars (TASK-75's current framing). A command palette makes chrome-matching mostly moot: instead of comparing two menus, you skip menus.

## Proposed v1 scope
- Global keyboard shortcut (Cmd+K / Ctrl+K) opens a modal/overlay with a fuzzy-searchable list of pages.
- The searchable index is generated from `Rails.application.routes` introspection (named routes only, GET-only, no member/nested action noise) -- the route set already IS the sitemap, nothing to hand-maintain in a separate config file.
- Keyboard-only interaction: type to filter, arrow keys to move, Enter to navigate. Escape to close.
- Recently-visited ordering as a cheap v1 "frecency" signal (session or `Rails.cache`-backed recency list, no need for a full analytics model).
- Covers both public and admin routes in one unified list -- this is likely the more valuable overlap with TASK-75's "two disjoint nav systems" problem than trying to make them look alike.

## v2 candidates (not v1 scope)
- Search into records too (job postings by title, companies by name), not just static routes -- meaningfully bigger scope (needs a query layer, not just a route list).
- Command actions beyond navigation (e.g. "Favorite this posting" as a palette action from anywhere).

## Relationship to TASK-75
Not a replacement for TASK-75 (the two nav bars still need *some* baseline consistency/accessibility regardless of a palette existing), but likely reduces how much visual reconciliation actually matters once a fast keyboard path exists. Consider scoping/sequencing these together rather than treating the palette as pure addition on top of a separately-redesigned nav.

## Prior art worth referencing during implementation
Linear, GitHub (Cmd+K), Raycast/Spotlight-style overlays, VS Code's command palette -- all share the same core interaction shape (open, type, filter, arrow/select, dismiss) worth matching for muscle-memory familiarity rather than inventing new interaction conventions.
<!-- SECTION:DESCRIPTION:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Built v1 as scoped. `CommandIndex` introspects `Rails.application.routes` directly (filtered to named GET routes with no required dynamic segments, excluding Rails engine/API/Turbo internal routes), cached via `Rails.cache.fetch` -- 38 real entries, nothing hand-maintained. A small `LABEL_OVERRIDES` hash covers the ~10 routes where `.titleize` reads badly, reusing existing nav i18n labels where they already exist (e.g. "Saved Jobs", "Data Sources") for consistency with the nav bar.

`command_palette_controller.js` (Stimulus, mounted globally on `<body>`) uses a native `<dialog>` opened via `showModal()` -- gets focus-trap, Escape-to-close, and implicit `role="dialog"`/`aria-modal` for free, no hand-rolled JS needed for any of that. Global Cmd+K/Ctrl+K capture via `data-action="keydown@window->..."` (same pattern as the existing triage keyboard shortcuts). Simple contiguous-substring scorer, no fuzzy-matching dependency added for ~40 items. Recently-visited via `localStorage`, shown on empty query.

Verified live end-to-end in-browser, not just unit tests: real Cmd+K keypress opens it, typing "comp" correctly ranks "Companies" over "Admin Companies", Enter navigates to the right page, and the recent-visit list populated correctly on reopening after a real navigation.

Found and filed TASK-77 along the way -- a genuinely broken, pre-existing (not order-dependent) spec in `admin/documents_spec.rb`, confirmed unrelated to this work.

v2 candidates (record search, command actions) deliberately not built -- scope was v1 route-navigation only per the task description.
<!-- SECTION:FINAL_SUMMARY:END -->
