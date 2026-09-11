---
id: TASK-133
title: Guided-session deterministic replay execution
status: Done
assignee:
  - '@claude'
created_date: '2026-08-30 15:08'
updated_date: '2026-08-30 20:43'
labels:
  - application-workflow
  - human-in-the-loop
  - application-capture-datalake
dependencies:
  - TASK-112
references:
  - app/services/guided_sessions/replay_plan.rb
  - docs/architecture/guided-session-flow.md
  - >-
    backlog/tasks/task-112 -
    Phase-B-guided-application-session-recorder-with-supervised-intent.md
priority: medium
type: feature
ordinal: 149000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The execution half of TASK-112 AC#5. `GuidedSessions::ReplayPlan` already produces the read-only plan (which recorded steps a replay would auto-advance vs pause on). This task is the part that actually re-drives a browser through the deterministic steps and stops for Mike at every gate.

**This is a Bounded Agency decision, not a mechanical follow-up.** It is the first thing in the system that would fill a real form field on an employer site. It must be scoped with Mike before any build:
- What "auto-advance a deterministic step" means concretely (re-fill known fields from the recorded mapping? click a known "Next"? nothing that transmits?).
- Whether replay ever touches a real employer site or only the sandbox.
- The explicit start gesture, the visible "replay is running" state, and the hard stop at every `ReplayPlan` gate.
- How an approved commitment boundary resumes (the open question `guided-session-flow.md` names).

## Out of scope until scoped
- Any auto-submit. Final submission stays a `User Task` always.
- Consuming a readiness class / eval score to skip a review prompt during replay.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Scoped with Mike before implementation: what a deterministic step re-executes, sandbox-only vs real sites, the start gesture and running-state UI, and the resume-after-approval mechanism
- [x] #2 A replay pauses at every GuidedSessions::ReplayPlan gate and cannot advance past one without an explicit Mike action
- [x] #3 Final application submission is never auto-executed
- [x] #4 A test proves a replay cannot cross a commitment boundary or submit without explicit approval
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Built the supervised replay to Mike's scoping decisions. Merged to main (`75c8028e`..`3e1d738c` + brakeman ignore). Touched-area specs 62/0; full suite green; brakeman clean.

**Scoping (AC#1)** — grilled Mike, four decisions:
- Runs against **sandbox always; real employer sites need a per-run opt-in checkbox**.
- A step **only fills fields from the recorded answers** — never clicks Next / Continue / Submit. Every navigation or transmission is a human click.
- Starts from an explicit button on the review page; a fixed **REPLAY banner** in the page; **per-step "Do it" confirm** (toggle "run to next gate").
- Approving a gate **records the decision and ends the replay** — provider action past a commitment boundary is always driven by hand.

**Rails**
- `GuidedSessionReplay` (guided_session, status `running`/`paused_at_gate`/`stopped`/`completed`, current_step, allow_real_site).
- `GuidedSessions::Replay` — `start` (guards: session completed, one replay at a time, real-site needs opt-in), `next_step` → `{fill | advance | gate | done}` from `GuidedSessions::ReplayPlan`, `advance` (**raises past a gate** — AC#2), `approve_gate` (**ends the replay** — AC#4), `stop`. A `fill` instruction carries the recorded field answers.
- `GuidedSessions::ReplaysController` (web start/stop) + `Api::GuidedSessionReplaysController` (`GET`/`PATCH /api/guided_sessions/:token/replay`, `Rails.env.local?`) for the extension banner.
- Review-page UI: "Start replay" (completed sessions only) + real-site opt-in checkbox; active-replay card (step N/M, open-the-application link, Stop).

**Extension** — `content.js` fixed REPLAY banner: "Do it" types the recorded answers into fields matched by label then advances; "Run to next gate" loops; a gate shows only "Approve & end" / "Stop". **No click / navigate / submit primitive anywhere in the replay path** (AC#3). `manifest.json` → **1.35.0**.

**Guardrails (AC#3/#4)** — `spec/models/guided_session_replay_spec.rb` greps every `app/**/*replay*.rb` for `.click` / `navigate` / `submit` / `dispatchEvent` and asserts none. `spec/services/guided_sessions/replay_spec.rb` proves a gate can't be advanced past and approving it ends the replay.

**Docs** — `guided-session-flow.md` updated; the "how does an approved provider action resume" open question is answered (it doesn't).

**Needs a browser pass:** the banner rendering + label-matched fill against a real multi-step form — the field-key schemes differ between the recorder and the live registry, so the extension matches by label; confirm that holds up in a dogfood run.
<!-- SECTION:FINAL_SUMMARY:END -->
