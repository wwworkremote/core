---
id: TASK-83
title: >-
  Ingest application history from platform-managed apply systems (LinkedIn Easy
  Apply, Indeed Apply, Greenhouse, Workday)
status: To Do
assignee: []
created_date: '2026-08-22 19:43'
updated_date: '2026-08-24 16:34'
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
- [x] #1 LinkedIn applied-list entries import as applied transitions on the correct JobPosting
- [x] #2 Indeed applied-list entries do the same
- [x] #3 Transitions are recorded at the real application date, not import time
- [x] #4 List rows with no matching JobPosting are handled explicitly (created or held), never silently dropped
- [x] #5 Re-running a backfill does not duplicate applications or create duplicate PipelineSteps
- [ ] #6 A Greenhouse submit is captured even when the posting was not already tracked with a wwr_id
- [ ] #7 Every selector used was verified against a live page, not inferred
- [ ] #8 extension/manifest.json version bumped
- [ ] #9 Providers register against one shared applied-list adapter shape, not four bespoke integrations
- [x] #10 Whether my.greenhouse.io aggregates across tenants is verified before any Greenhouse design work
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

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## 2026-08-23 — LinkedIn half landed via saved-page import, not the extension

`bin/import_linkedin_tracker <stage> <saved-html>` (commit 0ff408a2, idempotency fix follows). **Tracked applications went 4 -> 14.**

**Mechanism differs from the plan and the difference matters.** The plan assumed an extension DOM read of the live tracker. I used a "Save Page As -> Complete" of the same page instead. Same data, same read-only risk profile, no extension work — but it only solves *backfill*. Ongoing capture still wants the extension path, so AC #9 (one shared applied-list adapter) is untouched and still correct as written.

Imported: 10 applied, 8 clicked_apply, 10 saved.

**`clicked_apply` is recorded as favorite, not applied** — LinkedIn only knows he left for the employer's site, not that he finished. Recording those as applied would have inflated the funnel by 8.

**Dedup is on the LinkedIn job id inside `target_url`, not our signature** (AC #4/#5). The same posting routinely arrives twice: once scraped from a LinkedIn job-alert email (source "Email (LinkedIn)") and once from the tracker. #5653 and #5654 were already in the DB under these exact ids. A match also backfills `company_name`, which email-scraped LinkedIn rows arrive without.

AC #3 (real date): partially. LinkedIn gives relative ages only ("Applied 3mo ago"), so the date is approximate and stored as approximate in `UserJobPosting.notes` — there is no `applied_at` column to put it in. Five of the ten applications date to ~2026-05-23; that gap is real signal for TASK-81.

AC #5 verified by re-running: JP.applied 12, UJP.applied 12, PipelineStep 410, notes length 722 — all unchanged.

### Blocked on the human (see HUMAN.md)

- **AC #2 Indeed — cannot proceed.** The saved `My jobs _ Indeed.html` is the app shell only: `window._initialState` carries config, the job list loads by XHR afterward, and the file contains zero job ids. Needs a re-save after the list renders.
- **AC #10 Greenhouse — cannot verify.** The saved `MyGreenhouse.html` is **0 bytes**. Whether `my.greenhouse.io` aggregates across tenants is still unknown, so Tier 2 vs Tier 3 is still undecided.

### Also worth knowing

The applications and the ingestion corpus are **nearly disjoint**. Of 28 LinkedIn tracker rows, only 3 already existed among 6,136 ingested postings. The pipeline is not surfacing the jobs he actually applies to — that is a bigger finding than the backfill itself and belongs in TASK-81's analysis.

**Correction 2026-08-23 — the disjointness inference is withdrawn.**

The measurement stands: of 28 LinkedIn tracker rows, only 3 already existed among 6,136 ingested postings. The inference drawn from it above — "the pipeline is not surfacing the jobs he actually applies to" — does not.

Mike's answer (HUMAN.answered.md #7): he was applying while the ingestion system was still being built out, because he had to. The near-disjointness is **chronology, not a targeting defect**. His applications predate the corpus that would have contained them.

Two consequences:

- **Do not retune ingestion against the 14 backfilled applications as ground truth.** That was the proposed fix and it is wrong — it would tune the corpus toward a sample that predates the corpus.
- **TASK-81 should measure the funnel from the backfill forward**, not treat historical overlap as a quality metric. Overlap before 2026-08 measures when the pipeline was built, not how well it aims.

What survives as a real gap: coverage of the surfaces he actually browses, which is blocked on the two exports that captured nothing (AC #2 Indeed, AC #10 Greenhouse).

## 2026-08-24 — Greenhouse and Indeed both landed. Tracked applications 12 -> 55.

Both blocked ACs are now closed, and the mechanism was the same in each case: **the saved DOM was never going to work, and the HAR capture did.** Mike re-saved both pages *and* captured HARs; only the HARs carried data.

### AC #10 — my.greenhouse.io DOES aggregate across tenants (Tier 1, not Tier 3)

`GET my.greenhouse.io/applications.json?page=N&active_only=true` returns applications spanning every Greenhouse-powered company, not one board at a time. **32 applications captured across 6 pages; `total_applications: 36`** (the remainder are inactive/archived, not fetched by `active_only=true`).

This was the open question gating Tier 2 vs Tier 3 in the implementation plan. It is Tier 1. The plan's Tier 2 caveat can be struck.

Record shape: `{id, job_post_id, job_post_url, job_title, company_name, locations, description, applied_at}`. **`applied_at` is an exact ISO 8601 timestamp** — strictly better than LinkedIn, which only exposes relative ages.

### AC #2 — Indeed via api/v1/appStatusJobs

The saved DOM really is an app shell; the re-save confirmed it. The data is at `GET myjobs.indeed.com/api/v1/appStatusJobs`: **15 applications**, with `applyTime` in epoch ms (exact), plus `jobKey`, `jobUrl`, `company.name`, `location`, and a status block.

**Bonus not in scope:** that payload also carries `applicationStatus`, `candidateStatus`, `employerJobStatus`, and `selfReportedStatus`. Outcome tracking was explicitly out of scope for this task, but Indeed hands it over for free if a follow-up wants it.

### AC #3 is now genuinely satisfied, not partially

Added `user_job_postings.applied_at` (migration `20260824154909`). Previously the real date could only go in a note, because there was no column for it. **44 of 55 tracked applications now carry a real date.**

The index sorts on `COALESCE(applied_at, created_at)` so pre-column rows sort by when we learned of them rather than clumping at one end, and the view labels those "tracked" rather than presenting import time as an application date.

### Cross-source dedup was necessary, not defensive

Added `Applications::PostingMatcher`. The same application now arrives from four places with a different URL and id in each. **ApartmentIQ and Temporal Technologies appear in both the Greenhouse and Indeed exports** — without a company+title fallback they would each have been counted twice, which is precisely the funnel inflation this backfill exists to prevent.

Match order: signature -> native id in `target_url` -> exact `target_url` -> normalized company+title. Exact-normalized rather than fuzzy; TASK-78's overlap coefficient would also catch "Files.com" vs "Files.com, Inc", but exact match has no false-positive mode and covers the overlap actually observed.

### Two HAR gotchas worth keeping

1. **Chrome mixes encodings within one capture.** Greenhouse pages 3 and 4 of 6 were base64; the rest were plain text. Reading only `.text` drops a third of the data **with no error**. Check `.response.content.encoding`.
2. **A logged-in HAR carries live session cookies** in its request records. Both importers parse response bodies only and never touch headers.

### Still open

AC #6 (Greenhouse submit capture without a pre-set `wwr_id`), #8 (manifest bump), #9 (shared adapter shape), #11 (Workday). Note #9 is now *more* justified: three importers exist and only the matcher is shared.

Also: `~/Desktop/inbox` moved to `~/ai/inbox` on 2026-08-24 — `~/Desktop` is TCC-blocked and unreadable from this environment.
<!-- SECTION:NOTES:END -->
