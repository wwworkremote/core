---
id: TASK-78
title: >-
  Extension: surface Greenhouse application questions with copy-paste-ready
  prebaked answers
status: In Progress
assignee: []
created_date: '2026-08-19 21:26'
updated_date: '2026-08-21 18:54'
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
<!-- SECTION:NOTES:END -->
