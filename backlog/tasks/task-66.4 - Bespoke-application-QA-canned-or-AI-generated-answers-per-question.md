---
id: TASK-66.4
title: 'Bespoke application Q&A: canned or AI-generated answers per question'
status: Done
assignee:
  - claude
created_date: '2026-08-17 23:13'
updated_date: '2026-08-18 14:46'
labels:
  - ux
  - job-postings
  - ai
dependencies:
  - TASK-66.1
parent_task_id: TASK-66
type: feature
ordinal: 75000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Part of TASK-66, targets the unified page from the view-merge subtask. Job applications frequently include custom screening questions (e.g. "Why do you want to work here?", "What's your notice period?", "Describe your experience with X"). Nothing in the current data model or UI represents these -- confirmed no existing "application_question"/"screening_question" concept anywhere in app/, and the Lead#discovery JSON captured by the browser extension does not currently include them either.

The user wants to submit a set of these questions per job application and get back answers primed from their CareerProfile/WorkExperience history (the same data LLM::ArtifactGenerator::PromptBuilder already draws on for cover letters -- skills, goals, structured work experience with action/impact/context). Per the user: some questions are answerable directly/deterministically from structured profile data with no LLM call needed ("canned" answers -- e.g. years of experience, notice period, work authorization, if such fields exist or are added to CareerProfile), while others are open-ended/complex enough to need an LLM-generated answer, and which path a given question takes should be decided per-question based on its complexity, not globally.

This needs: a way to store a set of questions against a job posting/application, a way to store or generate the corresponding answers, some mechanism for deciding canned-vs-AI per question, and a UI on the job posting page to add questions and view their answers.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A user can enter one or more application screening questions against a specific job posting
- [x] #2 Each question receives an answer: either pulled directly from structured CareerProfile data (canned) or generated via an LLM call primed with CareerProfile/WorkExperience data (AI), with a visible indication of which path was used
- [x] #3 The canned-vs-AI decision is made per question, not as an all-or-nothing toggle for the whole set
- [x] #4 Questions and their answers persist and are viewable on return visits to the job posting page, not just immediately after generation
- [x] #5 AI-generated answers follow the same profile-incomplete/expired-posting guard pattern already used by LLM::ArtifactGenerator (see validate/incomplete_profile_error/expired_error) rather than silently failing
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Research findings

- Direct precedent for this whole shape already exists: InterviewSession/
  InterviewQuestion (belongs_to job_posting + user, plain question_text/
  answer_text columns, Admin::*Controller#create with redirect_to
  @job_posting + notice/alert, no factory -- request specs build records
  directly). Following that pattern exactly for consistency.
- The validate/guard pattern (profile-incomplete/expired-posting errors)
  that AC #5 points to is already duplicated verbatim across
  LLM::ArtifactGenerator and LLM::ProfileMatcher, not extracted into a
  shared module -- established codebase convention is duplication over a
  premature shared concern for 2-3 call sites. Following that precedent,
  not extracting, for the 3rd occurrence here.
- Checked real CareerProfile data in dev: `location_info` jsonb has
  `{"display" => "Chicago, IL", ...}`, `contact_info` jsonb has
  `{"github" => {"url"=>...}, "linkedin" => {"url"=>...}, ...}`,
  `work_experiences` have start_date/end_date (end_date nil = current
  role). No notice_period/work_authorization/salary fields exist anywhere
  in the schema.
- Scope decision: the task description's "e.g. years of experience,
  notice period, work authorization" were examples, not requirements.
  Implementing canned answers only from data that already exists today
  (years of experience computed from work_experience date ranges,
  location, GitHub/LinkedIn links) -- zero new CareerProfile fields or
  profile-editing UI. Adding notice_period/work_authorization as real
  profile fields a user can fill in is a separate, later scope decision
  (worth its own task if wanted), not assumed here.
- Canned-vs-AI decision mechanism: deterministic keyword-regex matching
  against the question text (no LLM call spent just to classify), each
  pattern paired with a lambda that derives the answer from CareerProfile.
  If a pattern matches but the underlying data is blank, falls through to
  the AI path rather than erroring -- "not answerable this way right now,"
  not a failure.

## Plan

1. Migration: `create_table :application_questions` (job_posting
   references, user references, question_text text, answer_text text,
   answer_source string, timestamps) -- mirrors
   20260423005144_create_interview_laboratory.rb's table-creation style.
2. `ApplicationQuestion` model: belongs_to :job_posting, :user; validates
   question_text presence. Add `has_many :application_questions,
   dependent: :destroy` to JobPosting and User.
3. `LLM::AnswerGenerator::CannedAnswers` (new nested class, own file):
   `.match(question_text, profile)` -- array of {matcher: regex, answer:
   ->(profile){...}} pairs (years of experience from work_experience
   dates, marked with a `ponytail:` comment for the known
   gap/overlap-blind approximation; location; github; linkedin), returns
   the first non-blank match or nil.
4. `LLM::AnswerGenerator::PromptBuilder` (new nested class, own file):
   mirrors ArtifactGenerator::PromptBuilder's shape/prompt structure,
   parameterized by question_text instead of a fixed cover-letter task.
5. `LLM::AnswerGenerator` (new service): `.call(question, force: false)`
   -- tries CannedAnswers first (instant, no LLM); falls to the
   validate/guard + LLM::Orchestrator.call path (same shape as
   ArtifactGenerator/ProfileMatcher) if no canned match. Persists
   answer_text + answer_source onto the already-created question via
   update!, returns {success:, answer:, source:} or {success:, error:}.
   Does NOT create the question record itself -- that's the controller's
   job, so a typed question always persists even if answer generation
   fails.
6. `Admin::ApplicationQuestionsController` (new): #create builds+saves
   the question under @job_posting, then calls AnswerGenerator and
   redirects with a notice naming the source (canned/ai) or an alert with
   the guard's error if generation failed (question stays saved either
   way). #destroy removes a question, redirects to the job posting.
7. Routes: `resources :application_questions, only: %i[create destroy]`
   nested under admin `resources :job_postings`, matching the existing
   :contacts nesting exactly.
8. View: new "Application Q&A" card on job_postings/show.html.erb,
   placed after the Cover Letter panel (groups all
   application-generation features together) -- textarea + submit to ask
   a question, list of existing questions each showing the question text,
   a Canned/AI-Generated badge, the answer (or a "no answer yet" note if
   generation failed), and a delete button. New i18n keys under
   `job_postings.show.qa`.
9. Specs: model spec (associations/validations, mirrors
   interview_session_spec.rb), LLM::AnswerGenerator::CannedAnswers spec
   (each pattern, blank-data fallthrough), LLM::AnswerGenerator spec
   (mirrors artifact_generator_spec.rb -- canned path, AI path via mocked
   Orchestrator, guard failures, question persists on failure), request
   spec for the controller (mirrors interview_questions_spec.rb +
   interview_sessions_spec.rb combined shape).
10. Full RSpec suite + rubocop + erb_lint, then manual browser
    verification (ask a canned-answerable question, ask an
    AI-required question, confirm both display correctly and persist
    across a page reload) before finalizing.
<!-- SECTION:PLAN:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Built the bespoke application Q&A feature end-to-end: submit a screening question against a job posting, get an answer that's either pulled straight from structured profile data (instant, free) or generated by an LLM primed with the same profile/work-history data the cover letter already uses -- decided per question, not globally.

**Data model:** New `application_questions` table (job_posting + user references, question_text, answer_text, answer_source) and `ApplicationQuestion` model, mirroring the existing InterviewSession/InterviewQuestion pattern exactly (same belongs_to shape, same Admin::*Controller#create-with-redirect convention) for consistency with how this codebase already models similar per-job-posting user-generated records.

**Canned-vs-AI decision, made per question:** `LLM::AnswerGenerator::CannedAnswers.match(question_text, profile)` runs a small deterministic keyword-regex registry against the question text -- no LLM call spent just to classify. Four patterns ship, built only from CareerProfile data that already exists today (years of experience computed from work_experience date ranges, current location, GitHub/portfolio, LinkedIn) -- confirmed real, non-obvious phrasings against production-shaped dev data and fixed two regex bugs found that way (order-independent word matching for "years...experience" appearing in either order; "location/based/located" needing to match regardless of whether "where" precedes or follows). A pattern matching but the underlying profile data being blank falls through to the AI path rather than erroring. `LLM::AnswerGenerator` tries canned first, then the same validate/guard pattern (profile-incomplete / expired-posting) already established by ArtifactGenerator and ProfileMatcher -- deliberately not extracted into a shared module, matching this codebase's existing convention of duplicating that ~10-line guard across services rather than a premature abstraction for 2-3 call sites.

**Scope decision made explicit during planning:** the task description's "years of experience, notice period, work authorization" were examples, not requirements. Implemented canned answers only from CareerProfile fields that exist today; did not add notice_period/work_authorization/salary fields or any profile-editing UI for them -- that's a separate, later scope decision if wanted, not assumed here.

**Persistence semantics (AC #4/#5):** the question record is created by the controller and always persists, independent of whether answer generation succeeds -- so a guard failure or LLM error never loses what the user typed; the flash alert names the specific error and the question stays visible with a "no answer yet" note, retryable later.

**UI:** new "Application Q&A" card on the unified job_postings/show.html.erb page (grouped with the other AI-generation features -- Match Analysis, Cover Letter -- right above them was already Cover Letter, this sits directly after it), textarea + submit, each question shows the text, a "From Profile" or "AI Generated" badge, the answer or a failure note, and a delete button.

**Tests:** model spec, CannedAnswers spec (every pattern including blank-data fallthrough), AnswerGenerator spec (canned path with LLM::Orchestrator asserted un-called, AI path via mocked Orchestrator, both guard failures with question-persists assertions), controller request spec (create success both sources, create with guard failure, destroy), and job_postings_spec request coverage for the rendered panel. Full suite: 604 examples, 0 failures. Rubocop and erb_lint clean -- along the way, found and removed two pieces of genuine dead code in JobPosting (a 16-line commented-out rails_admin block, and an add_pipeline_note method that was never called anywhere -- only Company's own separate copy is ever used) that were needed to stay under Metrics/ClassLength after adding the new association.

**Manual verification, real browser against real dev data (job posting 5817, profile with 15 actual work_experiences):** submitted "How many years of experience do you have?" through the live form -- answered instantly as "26 years" (canned, matching the real computed tenure). Submitted an open-ended question ("Describe a challenging bug you fixed recently.") -- this one actually reached a real local LLM and got a substantive first-person answer back (source: ai), confirming the full Orchestrator round-trip works, not just the mocked spec path. Reloaded the page fresh and confirmed both questions, their answers, and correct badges persisted. Deleted one question through the live delete button and confirmed it was gone from the DB.

**All four TASK-66 subtasks are now done.** TASK-66 (the parent) can be closed once you're satisfied, or left open if you want a final pass across the whole unified page.
<!-- SECTION:FINAL_SUMMARY:END -->
