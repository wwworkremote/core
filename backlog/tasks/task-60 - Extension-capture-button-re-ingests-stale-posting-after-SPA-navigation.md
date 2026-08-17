---
id: TASK-60
title: 'Extension: capture button re-ingests stale posting after SPA navigation'
status: Done
assignee: []
created_date: '2026-08-17 01:37'
updated_date: '2026-08-17 01:37'
labels: []
dependencies: []
modified_files:
  - extension/content.js
  - extension/manifest.json
priority: high
type: bug
ordinal: 65000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
On SPA job boards (LinkedIn, Indeed split-view) the content script loads once per full page load; clicking into a different posting only does a client-side `pushState`, no reload. The overlay's "CAPTURE THIS JOB" button click handler (`extension/content.js`) short-circuited to `notifyPanel(cachedExtraction)` whenever `cachedExtraction` was already set from a prior capture on the same page load -- so browsing job A, capturing it, then navigating to job B and clicking capture again silently re-submitted job A's data instead of extracting job B.

The existing `markPanelStale()` SPA-navigation hook (already wired to `pushState`/`popstate`) flagged the panel UI as stale but never cleared the cache, so it didn't actually fix the flow.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Navigating to a new posting within an SPA board resets cachedExtraction/leadId so the next capture click re-extracts and creates a new Lead
- [x] #2 Overlay preview/badge/lead-status visibly reset on navigation instead of showing the previous posting's data
- [x] #3 node --check and npm run lint:extension pass; manifest.json version bumped
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added resetForNewPage() (clears cachedExtraction/leadId/leadCapturePromise, resets overlay preview/badge/lead-status DOM) and call it from markPanelStale(), which was already correctly hooked to pushState/popstate for SPA boards. Root-caused via the capture-btn click handler's `if (captureMode === 'enrich' || cachedExtraction)` short-circuit in extension/content.js. manifest.json bumped 1.10.4 -> 1.10.5. node --check and npm run lint:extension both clean.
<!-- SECTION:FINAL_SUMMARY:END -->
