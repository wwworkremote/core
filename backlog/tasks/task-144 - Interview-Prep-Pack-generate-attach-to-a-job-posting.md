---
id: TASK-144
title: 'Interview Prep Pack: generate & attach to a job posting'
status: In Progress
assignee:
  - mike@just3ws.com
created_date: '2026-09-02 16:44'
updated_date: '2026-09-02 16:45'
labels:
  - job-search
  - llm
dependencies: []
references:
  - docs/research/interview-prep-basis-dsp.md
  - 'https://jobs.lever.co/basis/bb213682-6e49-48d4-bdfe-3b17aba79366'
priority: high
type: feature
ordinal: 160000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Mike gets warm-intro interviews on short notice and needs prep fast. Today that prep is hand-built each time. Give the job-posting flow a one-click "generate interview prep pack" that produces a bespoke, reviewable markdown brief from his résumé + the posting + what the system already knows about the company, editable in place and regenerable — the same shape as the existing cover-letter generator, surfaced in the job posting's Interview notes section.

The worked reference that defines the target structure and depth is docs/research/interview-prep-basis-dsp.md (Part 2 is the generalized per-section spec). The existing InterviewSession/InterviewQuestion/InterviewTask models and the small INTERVIEW_PREP snippet inside LLM::ProfileMatcher stay as they are; this is a new standalone artifact, not a change to those.

Prompted by a real Basis (Lever) interview on 2026-09-03.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A button in the job posting Interview notes section generates an interview prep pack for that posting and persists it against the user's record for that posting
- [ ] #2 The generated pack contains these sections: setup/role reality, 90-second story arc, ranked company hooks, referral play (only when a Contact is linked to the posting), likely questions incl. known résumé soft spots, questions to ask them, night-before checklist
- [ ] #3 Generation is grounded in the candidate's structured work history, the posting text, and any stored Company reputation audit; it does not fabricate titles, dates, or metrics
- [ ] #4 A referral section appears only when the posting has a linked Contact, and is cleanly omitted otherwise
- [ ] #5 Mike can edit the pack text in place and the edit persists across reloads
- [ ] #6 Regenerating overwrites the pack and updates a visible 'generated at' timestamp
- [ ] #7 The prompt is admin-overridable via PipelinePrompt with a hardcoded fallback, consistent with other LLM prompt builders
- [ ] #8 Posting body text passes through the existing guardrails path (no untrusted text reaches the model unscreened)
- [ ] #9 RSpec covers: profile-incomplete guard, expired-posting guard with force override, success path writes the column, referral-present vs absent prompt difference, and the new controller action
- [ ] #10 CONTEXT.md domain language and docs/agents/changelog.md are updated in this task
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
Full approved plan: /Users/mike/.claude/plans/snuggly-dazzling-candy.md

Clone the cover-letter generation path for a new artifact type. Storage = text column on user_job_postings next to cover_letter (deliberately NOT InterviewSession).

1. Migration: add user_job_postings.interview_prep_pack (text) + interview_prep_pack_generated_at (datetime); annotaterb refresh.
2. Service app/services/LLM/interview_prep_generator.rb — mirror LLM::ArtifactGenerator (same two guards: profile has work_experiences; not expired unless force). Model via LLM::Registry.model_for(:interview_prep) with commented defaults.interview_prep stanza in config/models.yml.
3. Prompt builder app/services/LLM/interview_prep_generator/prompt_builder.rb — mirror ArtifactGenerator::PromptBuilder; PipelinePrompt.render_for("interview_prep_pack", locals) { default_prompt }. Inputs: profile skills/goals/experience_level + ordered work_experiences (experience_block shape from ProfileMatcher::PromptBuilder); posting title/company/body; Company disposition + glassdoor_data["reputation_audit"] if present; user_job.match_analysis if present; job_posting.contacts for referral section; standing criteria as fixed text (200k floor, culture>comp, US-only, role sized to stage). Output-structure instruction names the 7 sections from docs/research/interview-prep-basis-dsp.md Part 2. ponytail: comment — no live web research in v1.
4. Controller+route: post :generate_interview_prep on user_job_postings; action mirrors generate_artifacts; add :generate_interview_prep to before_action :set_job_posting; add :interview_prep_pack to user_job_posting_params expect list.
5. View job_postings/show.html.erb Interview notes card (~line 113), above New Session Form: present→markdown render + clipboard copy (copy cover_letter block ~465) + generated-at + Regenerate button_to(force:true) + <details> textarea edit form (mirror Personal Notes ~480); absent→Generate button + helper (mirror no_match_yet).
6. i18n config/locales/en.yml under job_postings.show.interview_notes: prep_heading, generate_prep, regenerate_prep, prep_generated_at, no_prep_yet, prep_helper, edit_prep, save_prep, copy.
7. Specs: interview_prep_generator_spec (guards, force, success writes column), prompt_builder_spec (posting title/company + experience + referral-present-vs-absent + section instruction + PipelinePrompt fallback), user_job_postings request spec generate_interview_prep example.
8. Docs: CONTEXT.md domain language "Interview Prep Pack"; changelog entry; one-line "Implemented by TASK-144" note atop docs/research/interview-prep-basis-dsp.md.

Verification: db:migrate; rspec the 3 files; rubocop the new files; manual against Basis posting (UJP #268) — generate/edit/persist/regenerate; confirm write via runner.

Out of scope v1: live web research; per-InterviewSession packs; auto-gen on status→interview; structured InterviewQuestion rows.
<!-- SECTION:PLAN:END -->
