---
id: TASK-60
title: 'Extension: capture button re-ingests stale posting after SPA navigation'
status: Done
assignee: []
created_date: '2026-08-17 01:37'
updated_date: '2026-08-17 02:33'
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
Fix landed in two passes -- the first attempt (resetForNewPage() wired to markPanelStale) was correct but markPanelStale never fired: it was hooked to intercepting history.pushState, and live testing on LinkedIn showed that never triggers -- LinkedIn's router bundle holds its own reference to the original pushState from before this content script (document_end) runs, so patching it after the fact is a no-op. Replaced the pushState/popstate interception with polling window.location.href every 750ms, which doesn't depend on which function reference the host page calls.

Live-verified end-to-end via browser automation against real LinkedIn postings: captured job A (Lead #62, Watchtower Labs), navigated to job B via the in-page job list (SPA nav, no reload), overlay correctly reset to "ready"/"Not yet captured", captured job B (Lead #63, AdviNOW Medical) -- both leads distinct and correct in the database. manifest.json bumped 1.10.5 -> 1.10.6.

Third pass: live-testing again surfaced a remaining race even with the cache reset and polling nav-detection working correctly. LinkedIn reuses the same DOM node for the description container across job selections (React swaps its contents in place), so waitForContent's "does the element exist" check resolved instantly on every navigation -- true from the very first job, so it never actually waited for the new job's content to render. Fixed by having waitForContent additionally require the element's textContent to differ from a snapshot taken after the previous extraction (lastExtractedSnapshot), falling back to the existing timeout ceiling if content never changes. manifest.json bumped 1.10.6 -> 1.10.7. Live-verified: 3 consecutive captures across different postings (Leads #64 Computer Science Experts, #65 Ironbeam) each correct and distinct, no stale carryover.
<!-- SECTION:FINAL_SUMMARY:END -->
