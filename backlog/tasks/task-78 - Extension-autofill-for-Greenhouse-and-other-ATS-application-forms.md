---
id: TASK-78
title: >-
  Extension: surface Greenhouse application questions with copy-paste-ready
  prebaked answers
status: In Progress
assignee: []
created_date: '2026-08-19 21:26'
updated_date: '2026-08-21 19:59'
labels: []
dependencies: []
references:
  - extension/content.js
  - app/models/application_question.rb
  - app/models/career_profile.rb
  - app/models/resume.rb
priority: medium
type: feature
ordinal: 91000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The user's stated dream, scoped down to a genuinely achievable v0 (their own words: "Even just reading the questions and allowing for copypaste and prebaked replies would be a blessing"): read the screening questions off a Greenhouse application page and surface each one next to its matching `ApplicationQuestion` answer (canned or AI, `answer_source` already distinguishes them -- TASK-66 built this) with a one-click copy button. No writing into the form at all -- pure extraction, which is exactly what the extension already does well, plus a lookup against data this app already generates.

## Why this is the right v0 (not full autofill)
- Read-only against the page: same risk profile as every existing extraction provider, none of full autofill's form-injection/PII-writing concerns.
- No live DOM-writing to get wrong -- if a question's text doesn't match anything, just don't show a suggestion for it, no silent-failure risk.
- Reuses 100% of existing infrastructure: `ApplicationQuestion#answer_text`/`#answer_source`, the extension's existing sidepanel UI, the existing `reportDiag` diagnostics pattern.

## Rough shape
- New extension capability: on a Greenhouse *application* page (not the job listing page -- unverified DOM, needs its own live-inspection pass first, same discipline as every other provider in `extension/content.js`), extract each screening question's text.
- Match each extracted question against this job posting's existing `ApplicationQuestion` rows by fuzzy text match on `question_text`.
- Render matches in the sidepanel: question text + its answer + a copy-to-clipboard button (the extension likely already has this pattern somewhere for other copyable data -- check before building fresh).
- Unmatched questions: either show nothing, or offer a "Get Answer" action that round-trips to the same AI-answer endpoint `ApplicationQuestion` already uses today from the web app.

## v2 (later, bigger, not this task's scope)
Actually writing prebaked answers into the form fields (true autofill), and expanding beyond Greenhouse to other ATS platforms (Lever, Workday, etc.). Bigger scope: field-mapping beyond just Q&A text (name/email/phone/resume upload), form-injection safety boundaries, a security-review pass. Revisit as a separate follow-on once this v0 is live and proven useful.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Extension extracts screening questions from a Greenhouse application page (read-only, never writes into the form)
- [x] #2 EEO/demographic self-identification questions are excluded from extraction
- [x] #3 Extracted questions are matched against this posting's existing ApplicationQuestion answers and rendered with a copy button
- [x] #4 Unmatched questions offer a Generate-answer action that round-trips to LLM::AnswerGenerator
- [x] #5 CareerProfile personal-info fields (name/email/phone/LinkedIn/GitHub/website/location) are copy-pasteable from the panel
- [x] #6 Application lifecycle status is visible and advanceable from the panel while on the ATS page
- [x] #7 Panel-driven status changes leave the same pipeline trail as web-UI ones
- [ ] #8 Verified live against a real Greenhouse posting, not just unit-tested
- [x] #9 The questions on the form and the answers the user actually typed are persisted when the application is marked applied
- [x] #10 Captured answers are tagged `submitted` and do not overwrite or relabel an unchanged canned/AI answer
- [x] #11 The ATS application URL is recorded on the pipeline step for the transition
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
2026-08-21 — v0 built and committed (c03d865d, extension v1.17.0).

**Shipped**
- `extractApplicationQuestions` off `#application-form`, keyed on Greenhouse's `id="question_<n>"` convention (live-verified on two real postings). EEO questions excluded for free: `#demographic-section` fields use plain numeric ids, never the `question_` prefix.
- Matching uses an **overlap coefficient**, not Jaccard. Live-testing showed Jaccard scores a genuine match far too low whenever the stored question is a shorter paraphrase of the page's full text — the union grows with the longer string and buries the containment. Threshold 0.7.
- `GET /api/v0/profile` + `ProfileContactFields` for the personal-info fields every application re-asks for.
- `GENERATE_ANSWER` relay for unmatched questions → `LLM::AnswerGenerator`.

**Scope added beyond the original v0** (from the stated product model: activate on the application page, keep control, track the process): the lifecycle half was dead on arrival, so it got fixed here rather than deferred — see the lifecycle note below.

**Fixed en route**: `OutboundLinksController` was dropping `wwr_id` on redirect, so the extension never knew which JobPosting it was on. Open-redirect guard untouched.

**Not yet verified**: the panel's rendered Application Status section (needs an extension reload; the Chrome side panel isn't capturable by automation). Data layer confirmed via console + live API.

**Still v2**: true autofill, non-Greenhouse ATS, resume upload, multi-page forms.

2026-08-21 (later) — lifecycle closed through submission (extension v1.18.0).

**The gap this closed**: the panel could record *that* an application went out but never what it asked or what was said in reply. Unless the user pressed "Generate answer", a screening question was extracted, matched, rendered — and then died with the page. Every application re-answered the same questions from scratch.

**Shipped**
- `extractApplicationQuestions` now also reads `el.value` (still read-only against the page; nothing is written into the form).
- Capture rides along with the existing `✓ Mark Applied` button rather than adding a second control — "I applied" and "here's what I answered" are one moment, and one round-trip means they can't half-land. No new endpoint, route, or controller.
- `POST .../application_status` accepts `answers` + `link`. Answers upsert by `question_text` (`answer_source: "submitted"`), blanks skipped, unchanged answers left alone so copying a canned answer verbatim doesn't relabel it as the user's own words.
- `PipelineStep#link` records the ATS URL — the one piece of context that's unrecoverable once a posting is taken down.
- Passive capture-phase `submit` listener snapshots the form, because Greenhouse replaces it with a confirmation view once accepted. Live-verified `#application-form` is a real `HTMLFormElement`, so the event actually fires.
- `answer_source_badge` helper: `submitted` renders "You Submitted", not "AI Generated". Provenance is the whole point of that badge.

**Security fix found en route**: `PipelineStep#link` is rendered with `link_to` and every writer feeds it outside-the-app input (admin note form, now the extension). No scheme check meant a `javascript:` value was a clickable payload in the user's own UI. Now validated http(s)-only at the model, which covers all three writers.

**Infra fix found en route**: `ops/nginx/servers/wwworkremote.conf` returned **301** for http→https. A 301 makes clients drop the request body (most also downgrade POST to GET), so an API POST to `http://wwworkremote.localhost` arrived with empty params and silently no-opped — 200 with `success:false`, nothing written. Changed to **308** (same permanent redirect, method and body preserved). The extension defaults to `http://localhost:31000` and so was never affected; anyone who pointed it at the nginx hostname over http would have been. Deployed copy at `/opt/homebrew/etc/nginx/servers/` still needs the user to sync + `nginx -s reload`.

**Live-verified** (over https, on a throwaway posting, cleaned up after; posting 6068 untouched): apply → `captured_answers: 2` with the blank third skipped, second transition → `captured_answers: 0` with no duplicate row and no relabel, `PipelineStep.link` set, and the web UI rendering both answers with the "You Submitted" badge.

**Still not visually confirmed**: the rendered side panel (Chrome side panels aren't capturable by automation). Data layer confirmed end-to-end.

**Still v2**: true autofill, non-Greenhouse ATS, resume upload, multi-page forms.
<!-- SECTION:NOTES:END -->
