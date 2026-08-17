---
id: TASK-66.4
title: 'Bespoke application Q&A: canned or AI-generated answers per question'
status: To Do
assignee: []
created_date: '2026-08-17 23:13'
updated_date: '2026-08-17 23:14'
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
- [ ] #1 A user can enter one or more application screening questions against a specific job posting
- [ ] #2 Each question receives an answer: either pulled directly from structured CareerProfile data (canned) or generated via an LLM call primed with CareerProfile/WorkExperience data (AI), with a visible indication of which path was used
- [ ] #3 The canned-vs-AI decision is made per question, not as an all-or-nothing toggle for the whole set
- [ ] #4 Questions and their answers persist and are viewable on return visits to the job posting page, not just immediately after generation
- [ ] #5 AI-generated answers follow the same profile-incomplete/expired-posting guard pattern already used by LLM::ArtifactGenerator (see validate/incomplete_profile_error/expired_error) rather than silently failing
<!-- AC:END -->
