---
id: TASK-78
title: >-
  Extension: surface Greenhouse application questions with copy-paste-ready
  prebaked answers
status: To Do
assignee: []
created_date: '2026-08-19 21:26'
updated_date: '2026-08-19 21:27'
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
