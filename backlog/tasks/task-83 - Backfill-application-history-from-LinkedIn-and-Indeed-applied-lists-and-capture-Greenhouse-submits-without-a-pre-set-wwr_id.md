---
id: TASK-83
title: >-
  Ingest application history from platform-managed apply systems (LinkedIn Easy
  Apply, Indeed Apply, Greenhouse, Workday)
status: To Do
assignee: []
created_date: '2026-08-22 19:43'
updated_date: '2026-08-22 19:46'
labels: []
dependencies: []
priority: high
type: feature
ordinal: 96000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The app records 4 applications. Mike has applied to substantially more, semi-manually and over months. Tracking has to work for applications made *outside* the extension, not just future ones.

Two different mechanisms, deliberately separated because one fixes history and the other only fixes the future.

## Phase 1 — Backfill from board-owned "applied" lists (higher value)

**LinkedIn and Indeed both maintain a server-side list of everything you applied to**, with dates and sometimes a status. That is ground truth for the funnel, it is retroactive, and it covers applications the extension never saw.

- LinkedIn: My Jobs → Applied (`/my-items/saved-jobs/` with an APPLIED card type).
- Indeed: My Jobs / Applied.

Both are read-only DOM reads of a page Mike is already logged into and looking at — same risk profile as the 16 existing extractors. No form interaction, no writes to the board.

**The real work is matching, not extraction.** These lists give title + company + date, not a `wwr_id`. Needs fuzzy matching back to existing `JobPosting` rows, and a decision for non-matches (create the posting from the list row, or hold for review). `extractApplicationQuestions`' overlap-coefficient matcher (TASK-78, threshold 0.7) is the existing prior art — reuse it rather than writing a second matcher.

Date matters: the transition should be recorded at the application's real date, not `Time.now`, or the funnel-staleness signal (TASK-81) is built on fiction.

## Phase 2 — Greenhouse submit capture without a pre-set wwr_id

Greenhouse has no central "my applications" list (it is per-tenant), so backfill is not available — per-submit capture is the only mechanism, and TASK-78 already built it: a capture-phase `submit` listener on `#application-form` that snapshots questions and answers and posts them with the status transition.

The gap is that it only fires when the posting is already in the system with `?wwr_id=NNN` set. Applying to a Greenhouse posting discovered any other way captures nothing. Needs: ingest-on-submit, creating the `JobPosting` from the page if it is not already known.

## Verification discipline
Every selector live-verified before implementation — no guessed DOM. Same standard as every existing provider. LinkedIn in particular re-renders its job surfaces frequently.

## Not in scope
Reading application *outcome* status (rejected / in review / interview). LinkedIn surfaces some of it, but it is inconsistent and would need its own pass. Recording that an application exists, and when, is the whole job here.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 LinkedIn applied-list entries import as applied transitions on the correct JobPosting
- [ ] #2 Indeed applied-list entries do the same
- [ ] #3 Transitions are recorded at the real application date, not import time
- [ ] #4 List rows with no matching JobPosting are handled explicitly (created or held), never silently dropped
- [ ] #5 Re-running a backfill does not duplicate applications or create duplicate PipelineSteps
- [ ] #6 A Greenhouse submit is captured even when the posting was not already tracked with a wwr_id
- [ ] #7 Every selector used was verified against a live page, not inferred
- [ ] #8 extension/manifest.json version bumped
- [ ] #9 Providers register against one shared applied-list adapter shape, not four bespoke integrations
- [ ] #10 Whether my.greenhouse.io aggregates across tenants is verified before any Greenhouse design work
- [ ] #11 Workday capture is opportunistic on candidate-home pages only, with no stored credentials and no scheduled sync
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Organizing principle: logins between you and the list

Most applications go through a platform's own apply flow, and each platform keeps its own record. Whether that record is *cheap* to reach is entirely a function of how many accounts it lives behind.

### Tier 1 — one login, one central list (build first)
- **LinkedIn Easy Apply** → My Jobs → Applied. One account, every Easy Apply in one place.
- **Indeed Apply** → My Jobs → Applied. Same shape.

Highest yield per unit of work, and between them they likely cover most of Mike's volume. Read-only DOM on a page he is already logged into.

### Tier 2 — verify before planning
- **Greenhouse.** Application tracking is per-tenant on the job boards themselves, but Greenhouse also ships a candidate-facing tracker (`my.greenhouse.io`) that may aggregate applications across Greenhouse-powered companies. **Unverified — check before designing for it.** If it aggregates, it is Tier 1. If not, it is Tier 3.

### Tier 3 — per-tenant login, opportunistic only
- **Workday.** Every tenant is a separate account with its own credentials; there is no cross-tenant view. Do not attempt scheduled sync, and do not touch credentials.

  The workable design is **opportunistic capture**: when Mike is already logged into a Workday tenant and lands on its candidate home, the extension ingests what is on screen. No stored credentials, no login automation, no background scraping. Same for any per-tenant Greenhouse board.

## Design consequence

Do not build four bespoke integrations. Build **one "applied list" adapter shape** — selector set plus row parser plus a date field — and register providers against it, exactly as the 16 posting extractors already work. Tier 3 providers then cost a parser each rather than an integration each.

## Boundaries
- Never store or enter credentials for any board. Mike logs in himself; the extension reads what is already rendered.
- No background or scheduled scraping of logged-in surfaces — capture happens on a page he has navigated to.
- Read-only. Nothing is written back to any board.
<!-- SECTION:PLAN:END -->
