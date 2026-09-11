---
id: TASK-97
title: Add an explicit awaiting-human/AI-hook state to the application pipeline
status: In Progress
assignee: []
created_date: '2026-08-27 02:19'
updated_date: '2026-08-27 03:18'
labels: []
dependencies: []
references:
  - TASK-82
  - TASK-96
  - docs/agents/domain.md
priority: medium
type: feature
ordinal: 112000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Live-tested the LinkedIn-to-application pipeline (2026-08-27, see JobPosting #6828/6829/6830) by hand: capture -> promote -> AnalysisJob/ProfileMatchJob -> pick a resume persona -> (next) generate resume export -> fill/submit on the ATS. Every judgment point in that chain currently happens as a live conversation with Claude rather than being a first-class state on UserJobPosting -- there's no record that a human review was required, requested, or given.

Mike wants a real "awaiting human" step modeled in the state machine itself (AASM, matching the pattern already used by JobPosting::StatusWorkflow and UserJobPosting), not just an in-conversation confirmation: something he can (1) see queued in the UI, (2) answer/approve without re-deriving context, and (3) that leaves a place for AI automation to plug in later (e.g. auto-suggest a persona, auto-draft an answer, then still wait for explicit approval before advancing).

Researched Camunda/Temporal as prior art during the live test -- conclusion was neither is worth adopting: Statesman would just duplicate the transition-history job PipelineStep already does, and Temporal's Ruby SDK means running a separate server for a single-user app. The recommendation is a plain AASM state with no auto-advancing event out of it (e.g. `awaiting_resume_approval`), consistent with the rest of this app's existing state-machine conventions.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A new AASM state exists on UserJobPosting (or wherever the application-submission flow lives) that a record can sit in indefinitely with no automatic transition out
- [x] #2 An explicit event exists for Mike to advance out of that state (approve/reject), callable from the UI and from the API
- [x] #3 The state and any AI-suggested content attached to it (e.g. a suggested persona) are visible on the job posting page, not just inferable from logs
- [x] #4 Leaves an obvious extension point for a future automated suggestion step (e.g. an AI-drafted answer or persona pick) to populate the pending record before a human approves it, without requiring this task to build that automation now
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
Camunda-lite design (no new dependency): `HumanTask` model (own table, not an AASM state on UserJobPosting -- several can be open on one posting at once) is the BPMN "User Task" equivalent; automated evaluator services are BPMN "Service Tasks" that only ever propose into a HumanTask's payload, never act directly.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
UX model clarified by Mike: PR-review style. Before anything submits, he wants to see and comment on the generated artifacts themselves (the drafted answers, the generated resume variant) inline, not just approve/reject a state -- closer to reviewing a diff/PR than clicking a single confirm button. Whatever UI implements the awaiting-human state should show the actual content pending approval (resume text, each Q&A pair) with a way to leave feedback per-item, not just a binary gate.

Built 2026-08-27: HumanTask model + migration (kind: persona_review/question_answer/resume_review/submit_approval, AASM pending->approved/rejected/edited), Pipeline::PersonaRecommender (LLM-backed evaluator, proposes a persona_id+confidence+rationale, never sets it), Admin::HumanTasksController + inbox view at /admin/human_tasks (PR-review style: shows the actual proposed content, Approve/Reject buttons). Live-tested against real postings: approve on a persona_review task applies the persona via the same path Api::V0::ApplicationContextsController#update uses; reject just resolves the task. Verified the AI's proposal is genuinely non-authoritative -- ran it against JobPosting #6829 (Kforce), it proposed staff_platform_enablement at 85% confidence, which contradicted my own earlier hand-judgment (posting has zero Rails/Ruby content) -- rejected it live, exactly the disagreement this gate exists to catch.

Deferred, not built: Pipeline::AnswerDrafter (LLM-drafted answers to application questions) -- needs careful design since it would draft from hostile scraped ATS form text, a real prompt-injection surface; resume_review and submit_approval HumanTask kinds have no evaluator producing them yet, only persona_review does. Inbox view only has a generic JSON-dump fallback for non-persona_review kinds -- fine for now since none exist yet, but will need real rendering once AnswerDrafter exists.

Added 2026-08-27 (2nd pass): HumanTask#stale? (pending >24h, matching the BPMN 2.0 by Example spec's Travel Booking timeout pattern) + HumanTask.stale scope + inbox sorted oldest-first with an amber warning badge on stale items. Deliberately NOT a background job or notification -- no email/Slack/push channel exists in this app to deliver a nudge through, so building one would be unrequested infra; this only drives visual escalation the next time the inbox page loads. Confirmed via rails runner (backdated a task 30h, stale? => true, .stale scope found it). Discussed and ruled out: AASM itself has no timer/escalation plugin (confirmed, not just assumed) -- any time-based behavior has to come from pairing it with a scheduled job, same pattern config/recurring.yml already uses elsewhere in this app. Also confirmed HumanTask + SolidQueue already satisfy the PoEAA durable-queue concern (both Postgres-backed, survive a crash) -- no additional queue/messaging pattern (Competing Consumers, Messaging Gateway) applies for a single-user app.
<!-- SECTION:NOTES:END -->
